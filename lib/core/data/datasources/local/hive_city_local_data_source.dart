import 'package:flutter_dozor_city/core/data/datasources/local/city_local_data_source.dart';
import 'package:flutter_dozor_city/core/domain/entities/app_lat_lng.dart';
import 'package:flutter_dozor_city/core/domain/entities/arrival_info.dart';
import 'package:flutter_dozor_city/core/domain/entities/city.dart';
import 'package:flutter_dozor_city/core/domain/entities/route_zone.dart';
import 'package:flutter_dozor_city/core/domain/entities/transport_route.dart';
import 'package:flutter_dozor_city/core/storage/hive_boxes.dart';
import 'package:hive/hive.dart';

class HiveCityLocalDataSource implements CityLocalDataSource {
  HiveCityLocalDataSource({
    required Box<dynamic> citiesBox,
    required Box<dynamic> routesBox,
  })  : _citiesBox = citiesBox,
        _routesBox = routesBox;

  final Box<dynamic> _citiesBox;
  final Box<dynamic> _routesBox;

  static const _citiesKey = 'cities';
  static const _citiesUpdatedAtKey = 'cities:updated_at';

  @override
  Future<void> clearCityData(String cityId) async {
    final routeKeys = _routesBox.keys
        .whereType<String>()
        .where(
          (key) =>
              key.startsWith('${HiveBoxes.routesCache}:$cityId:') ||
              key.startsWith('zones:$cityId-') ||
              key.startsWith('arrival:$cityId-'),
        )
        .toList(growable: false);
    await _routesBox.deleteAll(routeKeys);
  }

  @override
  Future<ArrivalInfo?> getArrivalByZone(String zoneId) async {
    final raw = _routesBox.get('arrival:$zoneId');
    if (raw is! Map) {
      return null;
    }
    return ArrivalInfo(
      zoneId: raw['zoneId'] as String,
      busMinutes: _readIntList(raw['busMinutes']),
      trolleyMinutes: _readIntList(raw['trolleyMinutes']),
      tramMinutes: _readIntList(raw['tramMinutes']),
    );
  }

  @override
  Future<DateTime?> getArrivalUpdatedAt(String zoneId) async {
    final raw = _routesBox.get(_arrivalUpdatedAtKey(zoneId));
    if (raw is String) {
      return DateTime.tryParse(raw);
    }
    return null;
  }

  @override
  Future<List<City>> getCities() async {
    final raw = _citiesBox.get(_citiesKey);
    if (raw is! List) {
      return const [];
    }
    return raw
        .whereType<Map>()
        .map(
          (item) => City(
            id: item['id'] as String,
            name: item['name'] as String,
            region: item['region'] as String,
            centerLat: (item['centerLat'] as num).toDouble(),
            centerLng: (item['centerLng'] as num).toDouble(),
            zoom: (item['zoom'] as num).toDouble(),
          ),
        )
        .toList(growable: false);
  }

  @override
  Future<DateTime?> getCitiesUpdatedAt() async {
    final raw = _citiesBox.get(_citiesUpdatedAtKey);
    if (raw is String) {
      return DateTime.tryParse(raw);
    }
    return null;
  }

  @override
  Future<List<TransportRoute>> getRoutesByType({
    required String cityId,
    required int transportType,
  }) async {
    final raw = _routesBox.get(_routesKey(cityId: cityId, transportType: transportType));
    if (raw is! List) {
      return const [];
    }
    return raw
        .whereType<Map>()
        .map(
          (item) => TransportRoute(
            id: item['id'] as String,
            shortName: item['shortName'] as String,
            title: item['title'] as String,
            transportType: (item['transportType'] as num).toInt(),
            polylineSegments: ((item['polylineSegments'] as List?) ?? const [])
                .whereType<List>()
                .map(
                  (segment) => segment
                      .whereType<Map>()
                      .map(
                        (point) => AppLatLng(
                          lat: ((point['lat'] as num?) ?? 0).toDouble(),
                          lng: ((point['lng'] as num?) ?? 0).toDouble(),
                        ),
                      )
                      .toList(growable: false),
                )
                .toList(growable: false),
            lineColorValue: (item['lineColorValue'] as num? ?? 0xFF1C4F7A)
                .toInt(),
          ),
        )
        .toList(growable: false);
  }

  @override
  Future<DateTime?> getRoutesByTypeUpdatedAt({
    required String cityId,
    required int transportType,
  }) async {
    final raw = _routesBox.get(
      _routesUpdatedAtKey(cityId: cityId, transportType: transportType),
    );
    if (raw is String) {
      return DateTime.tryParse(raw);
    }
    return null;
  }

  @override
  Future<List<RouteZone>> getRouteZones(String routeId) async {
    final raw = _routesBox.get('zones:$routeId');
    if (raw is! List) {
      return const [];
    }
    return raw
        .whereType<Map>()
        .map(
          (item) => RouteZone(
            id: item['id'] as String,
            routeId: item['routeId'] as String,
            name: item['name'] as String,
          ),
        )
        .toList(growable: false);
  }

  @override
  Future<DateTime?> getRouteZonesUpdatedAt(String routeId) async {
    final raw = _routesBox.get(_zonesUpdatedAtKey(routeId));
    if (raw is String) {
      return DateTime.tryParse(raw);
    }
    return null;
  }

  @override
  Future<void> saveArrivalByZone(ArrivalInfo arrivalInfo) async {
    await _routesBox.put('arrival:${arrivalInfo.zoneId}', <String, dynamic>{
      'zoneId': arrivalInfo.zoneId,
      'busMinutes': arrivalInfo.busMinutes,
      'trolleyMinutes': arrivalInfo.trolleyMinutes,
      'tramMinutes': arrivalInfo.tramMinutes,
    });
    await _routesBox.put(
      _arrivalUpdatedAtKey(arrivalInfo.zoneId),
      DateTime.now().toIso8601String(),
    );
  }

  @override
  Future<void> saveCities(List<City> cities) async {
    await _citiesBox.put(
      _citiesKey,
      cities
          .map(
            (city) => <String, dynamic>{
              'id': city.id,
              'name': city.name,
              'region': city.region,
              'centerLat': city.centerLat,
              'centerLng': city.centerLng,
              'zoom': city.zoom,
            },
          )
          .toList(growable: false),
    );
    await _citiesBox.put(_citiesUpdatedAtKey, DateTime.now().toIso8601String());
  }

  @override
  Future<void> saveRouteZones(String routeId, List<RouteZone> zones) async {
    await _routesBox.put(
      'zones:$routeId',
      zones
          .map(
            (zone) => <String, dynamic>{
              'id': zone.id,
              'routeId': zone.routeId,
              'name': zone.name,
            },
          )
          .toList(growable: false),
    );
    await _routesBox.put(_zonesUpdatedAtKey(routeId), DateTime.now().toIso8601String());
  }

  @override
  Future<void> saveRoutesByType({
    required String cityId,
    required int transportType,
    required List<TransportRoute> routes,
  }) async {
    await _routesBox.put(
      _routesKey(cityId: cityId, transportType: transportType),
      routes
          .map(
            (route) => <String, dynamic>{
              'id': route.id,
              'shortName': route.shortName,
              'title': route.title,
              'transportType': route.transportType,
              'lineColorValue': route.lineColorValue,
              'polylineSegments': route.polylineSegments
                  .map(
                    (segment) => segment
                        .map(
                          (point) => <String, dynamic>{
                            'lat': point.lat,
                            'lng': point.lng,
                          },
                        )
                        .toList(growable: false),
                  )
                  .toList(growable: false),
            },
          )
          .toList(growable: false),
    );
    await _routesBox.put(
      _routesUpdatedAtKey(cityId: cityId, transportType: transportType),
      DateTime.now().toIso8601String(),
    );
  }

  List<int> _readIntList(dynamic raw) {
    if (raw is! List) {
      return const [];
    }
    return raw.map((item) => (item as num).toInt()).toList(growable: false);
  }

  String _routesKey({
    required String cityId,
    required int transportType,
  }) {
    return '${HiveBoxes.routesCache}:$cityId:$transportType';
  }

  String _arrivalUpdatedAtKey(String zoneId) => 'arrival_updated_at:$zoneId';
  String _zonesUpdatedAtKey(String routeId) => 'zones_updated_at:$routeId';
  String _routesUpdatedAtKey({
    required String cityId,
    required int transportType,
  }) {
    return 'routes_updated_at:$cityId:$transportType';
  }
}
