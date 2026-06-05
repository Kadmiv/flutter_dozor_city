import 'package:dio/dio.dart';
import 'package:flutter_dozor_city/core/domain/entities/arrival_info.dart';
import 'package:flutter_dozor_city/core/domain/entities/city.dart';
import 'package:flutter_dozor_city/core/domain/entities/route_zone.dart';
import 'package:flutter_dozor_city/core/domain/entities/transport_route.dart';
import 'package:flutter_dozor_city/core/domain/entities/vehicle.dart';
import 'package:flutter_dozor_city/core/presentation/route_display_color.dart';
import 'package:flutter_dozor_city/core/network/dio_client.dart';
import 'package:flutter_dozor_city/features/city_data/data/batumi/batumi_api.dart';
import 'package:flutter_dozor_city/features/city_data/data/batumi/batumi_bus_location_dto.dart';
import 'package:flutter_dozor_city/features/city_data/data/batumi/batumi_city_catalog.dart';
import 'package:flutter_dozor_city/features/city_data/data/batumi/batumi_db_data_dto.dart';
import 'package:flutter_dozor_city/features/city_data/data/batumi/batumi_route_heading_resolver.dart';
import 'package:flutter_dozor_city/features/city_data/data/batumi/batumi_points_between_stations_dto.dart';
import 'package:flutter_dozor_city/features/city_data/data/batumi/requests/get_batumi_bus_locs_on_route_request.dart';
import 'package:flutter_dozor_city/features/city_data/data/batumi/requests/get_batumi_db_data_request.dart';
import 'package:flutter_dozor_city/features/city_data/data/batumi/requests/get_batumi_points_between_stations_request.dart';
import 'package:flutter_dozor_city/features/city_data/data/datasources/remote/city_remote_data_source.dart';
import 'package:flutter_dozor_city/core/domain/entities/app_lat_lng.dart';

class BatumiRemoteDataSource implements CityRemoteDataSource {
  BatumiRemoteDataSource(DioClient dioClient)
    : _batumiApi = BatumiApi(dioClient),
      _headingResolver = const BatumiRouteHeadingResolver();

  final BatumiApi _batumiApi;
  final BatumiRouteHeadingResolver _headingResolver;

  BatumiDbDataDto? _snapshot;
  BatumiPointsBetweenStationsDto? _points;
  int? _snapshotHash;

  @override
  Future<List<City>> getCities() async => const [BatumiCityCatalog.city];

  @override
  Future<void> preloadCityData(String cityId) async {
    if (cityId != BatumiCityCatalog.cityId) {
      return;
    }
    await _loadSnapshot(forceReload: true);
    await _loadPoints(forceReload: true);
  }

  @override
  Future<int> getCityDataHash(String cityId) async {
    if (cityId != BatumiCityCatalog.cityId) {
      throw DioException(
        requestOptions: RequestOptions(path: '/api/getDbData'),
        message: 'Unsupported Batumi city id: $cityId',
      );
    }
    final snapshot = await _ensureSnapshotLoaded();
    final points = await _ensurePointsLoaded();
    _snapshotHash = _calculateSnapshotHash(snapshot, points);
    return _snapshotHash ?? 0;
  }

  @override
  Future<List<Vehicle>> getCityVehicles(
    String cityId, {
    List<String>? routeIds,
  }) async {
    if (cityId != BatumiCityCatalog.cityId) {
      throw DioException(
        requestOptions: RequestOptions(path: '/api/getBusLocsOnRoute'),
        message: 'Unsupported Batumi city id: $cityId',
      );
    }
    final snapshot = await _ensureSnapshotLoaded();
    final points = await _ensurePointsLoaded();
    final routesById = snapshot.routesNames;
    final targetRouteIds = routeIds?.isNotEmpty == true
        ? routeIds!
        : routesById.keys.toList(growable: false);
    final vehiclesByRoute = await Future.wait(
      targetRouteIds.map((routeId) async {
        final routeMeta = routesById[routeId];
        final locations = await _batumiApi.getBusLocsOnRoute(
          GetBatumiBusLocsOnRouteRequest(routeId: routeId),
        );
        return locations
            .where((location) => location.status != -1)
            .map(
              (location) => _toVehicle(
                routeId: routeId,
                routeMeta: routeMeta,
                snapshot: snapshot,
                points: points,
                location: location,
              ),
            )
            .toList(growable: false);
      }),
    );
    return vehiclesByRoute.expand((items) => items).toList(growable: false);
  }

  @override
  Future<List<TransportRoute>> getRoutesByType({
    required String cityId,
    required int transportType,
  }) async {
    if (cityId != BatumiCityCatalog.cityId) {
      throw DioException(
        requestOptions: RequestOptions(path: '/api/getDbData'),
        message: 'Unsupported Batumi city id: $cityId',
      );
    }
    if (transportType != 0) {
      return const [];
    }
    final snapshot = await _ensureSnapshotLoaded();
    final points = await _ensurePointsLoaded();
    final routes = snapshot.routesNames.values.toList(growable: false)
      ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
    return routes
        .map(
          (route) => TransportRoute(
            id: route.routeId,
            shortName: route.shortName,
            title: route.titleKa.trim().isNotEmpty
                ? route.titleKa
                : route.titleEn,
            transportType: 0,
            polylineSegments: _buildPolylineSegments(
              routeId: route.routeId,
              snapshot: snapshot,
              points: points,
            ),
            lineColorValue: RouteDisplayColor.fromRouteIdentity(
              shortName: route.routeId,
              title: route.shortName,
            ),
          ),
        )
        .toList(growable: false);
  }

  @override
  Future<List<RouteZone>> getRouteZones(String routeId) async {
    final snapshot = await _ensureSnapshotLoaded();
    final stops =
        snapshot.busStops.values
            .where((stop) => stop.routes.containsKey(routeId))
            .toList(growable: false)
          ..sort((a, b) {
            final left = a.routes[routeId]?.order ?? 0;
            final right = b.routes[routeId]?.order ?? 0;
            return left.compareTo(right);
          });
    return stops
        .map(
          (stop) => RouteZone(
            id: stop.id,
            routeId: routeId,
            name: _preferredStopName(stop),
          ),
        )
        .toList(growable: false);
  }

  @override
  Future<ArrivalInfo> getArrivalByZone({
    required String cityId,
    required String zoneId,
  }) async {
    if (cityId != BatumiCityCatalog.cityId) {
      throw DioException(
        requestOptions: RequestOptions(path: '/api/getBusLocsOnRoute'),
        message: 'Unsupported Batumi city id: $cityId',
      );
    }
    return ArrivalInfo(
      zoneId: zoneId,
      busMinutes: const [],
      trolleyMinutes: const [],
      tramMinutes: const [],
    );
  }

  Future<BatumiDbDataDto> _ensureSnapshotLoaded() async {
    return _snapshot ??= await _loadSnapshot();
  }

  Future<BatumiDbDataDto> _loadSnapshot({bool forceReload = false}) async {
    if (!forceReload && _snapshot != null) {
      return _snapshot!;
    }
    final snapshot = await _batumiApi.getDbData(const GetBatumiDbDataRequest());
    _snapshot = snapshot;
    _snapshotHash = _points == null
        ? _snapshotHash
        : _calculateSnapshotHash(snapshot, _points!);
    return snapshot;
  }

  Future<BatumiPointsBetweenStationsDto> _ensurePointsLoaded() async {
    return _points ??= await _loadPoints();
  }

  Future<BatumiPointsBetweenStationsDto> _loadPoints({
    bool forceReload = false,
  }) async {
    if (!forceReload && _points != null) {
      return _points!;
    }
    final points = await _batumiApi.getPointsBetweenStations(
      const GetBatumiPointsBetweenStationsRequest(),
    );
    _points = points;
    if (_snapshot != null) {
      _snapshotHash = _calculateSnapshotHash(_snapshot!, points);
    }
    return points;
  }

  List<List<AppLatLng>> _buildPolylineSegments({
    required String routeId,
    required BatumiDbDataDto snapshot,
    required BatumiPointsBetweenStationsDto points,
  }) {
    final routePointsByStop = points.data[routeId];
    final routeStops =
        snapshot.busStops.values
            .where((stop) => stop.routes.containsKey(routeId))
            .toList(growable: false)
          ..sort((a, b) {
            final left = a.routes[routeId]?.order ?? 0;
            final right = b.routes[routeId]?.order ?? 0;
            return left.compareTo(right);
          });

    final segments = <List<AppLatLng>>[];
    if (routePointsByStop != null) {
      for (final stop in routeStops) {
        final stopPoints = routePointsByStop[stop.id];
        if (stopPoints == null || stopPoints.length < 2) {
          continue;
        }
        final segment = stopPoints
            .map((point) => AppLatLng(lat: point.lat, lng: point.lon))
            .toList(growable: false);
        if (segment.length > 1) {
          segments.add(segment);
        }
      }
    }
    if (segments.isNotEmpty) {
      return segments;
    }

    final coordinates = snapshot.routeCoordinatesGrouped[routeId];
    if (coordinates == null) {
      return const [];
    }
    final ordered = coordinates.orderedPoints
        .map((point) => AppLatLng(lat: point.lat, lng: point.lon))
        .toList(growable: false);
    if (ordered.length < 2) {
      return const [];
    }
    return [ordered];
  }

  Vehicle _toVehicle({
    required String routeId,
    required BatumiRouteNameDto? routeMeta,
    required BatumiDbDataDto snapshot,
    required BatumiPointsBetweenStationsDto? points,
    required BatumiBusLocationDto location,
  }) {
    final shortName = routeMeta?.shortName.isNotEmpty == true
        ? routeMeta!.shortName
        : routeId;
    final title = routeMeta?.titleKa.trim().isNotEmpty == true
        ? routeMeta!.titleKa
        : shortName;
    return Vehicle(
      id: '$routeId:${location.name}',
      routeId: routeId,
      routeShortName: shortName,
      routeTitle: title,
      transportType: 0,
      lat: location.lat,
      lng: location.lon,
      azimuth: points == null
          ? 0
          : _headingResolver.resolveAzimuth(
              routeId: routeId,
              location: location,
              snapshot: snapshot,
              points: points,
            ),
      speed: 0,
      govNumber: location.name,
    );
  }

  String _preferredStopName(BatumiBusStopDto stop) {
    if (stop.nameEn.trim().isNotEmpty) {
      return stop.nameEn;
    }
    if (stop.nameGeoGps.trim().isNotEmpty) {
      return stop.nameGeoGps;
    }
    if (stop.nameKa.trim().isNotEmpty) {
      return stop.nameKa;
    }
    return stop.id;
  }

  int _calculateSnapshotHash(
    BatumiDbDataDto snapshot,
    BatumiPointsBetweenStationsDto points,
  ) {
    final buffer = StringBuffer()
      ..write(snapshot.routesNames.keys.join('|'))
      ..write('#')
      ..write(snapshot.busStops.keys.join('|'))
      ..write('#')
      ..write(
        snapshot.routeCoordinatesGrouped.entries
            .map((entry) => '${entry.key}:${entry.value.orderedPoints.length}')
            .join('|'),
      )
      ..write('#')
      ..write(
        points.data.entries
            .map((entry) => '${entry.key}:${entry.value.length}')
            .join('|'),
      );
    return _stableHash(buffer.toString());
  }

  int _stableHash(String value) {
    var hash = 0x811c9dc5;
    for (final codeUnit in value.codeUnits) {
      hash ^= codeUnit;
      hash = (hash * 0x01000193) & 0x7fffffff;
    }
    return hash;
  }
}
