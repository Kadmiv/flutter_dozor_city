import 'dart:convert';

import 'package:http/http.dart' as http;

import '../domain/models.dart';
import '../logging/service_logger.dart';

class BatumiApiClient {
  BatumiApiClient({
    required this.baseUrl,
    http.Client? client,
    ServiceLogger? logger,
  }) : _client = client ?? http.Client(),
       _logger = logger ?? const ServiceLogger();

  final String baseUrl;
  final http.Client _client;
  final ServiceLogger _logger;

  Future<BatumiSnapshot> loadSnapshot() async {
    _logger.info('Fetching Batumi route snapshot from $baseUrl');
    final dbData = await _getJson('/api/getDbData');
    _logger.info('Fetched /api/getDbData');
    final points = await _getJson('/api/getPointsBetweenStations');
    _logger.info('Fetched /api/getPointsBetweenStations');

    final data = _readMap(dbData['data']);
    final stops = <StopRecord>[];
    final routes = <RouteRecord>[];
    final routeStops = <RouteStopRecord>[];
    final routePolylines = <RoutePolylineRecord>[];

    final busStops = _readMap(data['busStops']);
    for (final entry in busStops.entries) {
      final stop = _readMap(entry.value);
      stops.add(
        StopRecord(
          id: _string(stop['BusStopIdGeoGps']),
          name: _preferredName(stop),
          lat: _double(stop['BusStopLatitude']),
          lon: _double(stop['BusStopLongitude']),
          number: _int(stop['BusStopNumber']),
        ),
      );
      final rawRoutes = _readMap(stop['routes']);
      for (final routeEntry in rawRoutes.entries) {
        final routeId = routeEntry.key;
        final routeMeta = _readMap(_readMap(data['routesNames'])[routeId]);
        routeStops.add(
          RouteStopRecord(
            routeId: routeId,
            stopId: _string(stop['BusStopIdGeoGps']),
            stopOrder: _int(_readMap(routeEntry.value)['Order']),
            status: _int(_readMap(routeEntry.value)['Status']),
            times: _stringList(_readMap(routeEntry.value)['times']),
          ),
        );
        if (!routes.any((route) => route.id == routeId)) {
          routes.add(
            RouteRecord(
              id: routeId,
              shortName: _string(routeMeta['RouteNameEN']).isNotEmpty
                  ? _string(routeMeta['RouteNameEN'])
                  : routeId,
              title: _string(routeMeta['RouteNameKA']).isNotEmpty
                  ? _string(routeMeta['RouteNameKA'])
                  : _string(routeMeta['RouteNameEN']),
              transportType: 0,
              sortOrder: _int(routeMeta['RouteSortOrder']),
              isCircle: _bool(routeMeta['RouteIsCircle']),
            ),
          );
        }
      }
    }
    routes.sort((a, b) => a.sortOrder.compareTo(b.sortOrder));

    final routeCoordinatesGrouped = _readMap(data['routeCoordinatesGrouped']);
    for (final entry in routeCoordinatesGrouped.entries) {
      final routeId = entry.key;
      final pointsMap = _readMap(entry.value);
      final pointsList = <Map<String, Object?>>[];
      final keys = pointsMap.keys.toList(
        growable: false,
      )..sort((a, b) => (int.tryParse(a) ?? 0).compareTo(int.tryParse(b) ?? 0));
      for (final key in keys) {
        final point = _readMap(pointsMap[key]);
        pointsList.add({
          'lat': _double(point['lat']),
          'lon': _double(point['lon']),
        });
      }
      if (pointsList.isNotEmpty) {
        routePolylines.add(
          RoutePolylineRecord(
            routeId: routeId,
            segmentIndex: 0,
            points: pointsList,
          ),
        );
      }
    }

    _logger.info(
      'Parsed snapshot payload: routes=${routes.length}, stops=${stops.length}, routeStops=${routeStops.length}, polylines=${routePolylines.length}',
    );
    return BatumiSnapshot(
      routes: routes,
      stops: stops,
      routeStops: routeStops,
      routePolylines: routePolylines,
    );
  }

  Future<List<GpsPosition>> pollRoute(String routeId) async {
    _logger.info('Fetching live Batumi vehicles for route $routeId');
    final response = await _getJson(
      '/api/getBusLocsOnRoute',
      queryParameters: {'routeId': routeId},
    );
    final items = _readList(response['data']);
    final positions = items
        .map(_readMap)
        .where((item) => _int(item['Status']) != -1)
        .map(
          (item) => GpsPosition(
            vehicleId: '$routeId:${_string(item['Name'])}',
            routeId: routeId,
            timestampMs: DateTime.now().millisecondsSinceEpoch,
            lat: _double(item['Lat']),
            lon: _double(item['Lon']),
            speed: 0,
            azimuth: 0,
            govNumber: _string(item['Name']),
          ),
        )
        .toList(growable: false);
    _logger.info(
      'Parsed ${positions.length} active vehicles from /api/getBusLocsOnRoute?routeId=$routeId',
    );
    return positions;
  }

  Future<Map<String, Object?>> _getJson(
    String path, {
    Map<String, String>? queryParameters,
  }) async {
    final uri = Uri.parse(
      '$baseUrl$path',
    ).replace(queryParameters: queryParameters);
    _logger.info('GET $uri');
    final response = await _client.get(uri);
    if (response.statusCode < 200 || response.statusCode >= 300) {
      _logger.warn('HTTP ${response.statusCode} from $uri');
      throw StateError('HTTP ${response.statusCode} from $uri');
    }
    final decoded = jsonDecode(response.body);
    if (decoded is Map) {
      return decoded.map((key, value) => MapEntry('$key', value as Object?));
    }
    throw FormatException('Expected JSON object from $uri');
  }

  Map<String, Object?> _readMap(Object? raw) {
    if (raw is Map<String, Object?>) {
      return raw;
    }
    if (raw is Map) {
      return raw.map((key, value) => MapEntry('$key', value as Object?));
    }
    return <String, Object?>{};
  }

  List<Object?> _readList(Object? raw) {
    if (raw is List) {
      return raw.cast<Object?>();
    }
    return const [];
  }

  String _preferredName(Map<String, Object?> stop) {
    final en = _string(stop['BusStopNameEN']);
    if (en.isNotEmpty) return en;
    final ka = _string(stop['BusStopNameKA']);
    if (ka.isNotEmpty) return ka;
    return _string(stop['BusStopIdGeoGps']);
  }

  String _string(Object? raw) => raw == null ? '' : '$raw';
  int _int(Object? raw) =>
      raw is num ? raw.toInt() : int.tryParse(_string(raw)) ?? 0;
  double _double(Object? raw) =>
      raw is num ? raw.toDouble() : double.tryParse(_string(raw)) ?? 0;
  bool _bool(Object? raw) {
    if (raw is bool) return raw;
    final value = _string(raw).toLowerCase();
    return value == 'true' || value == '1';
  }

  List<String> _stringList(Object? raw) {
    if (raw is List) {
      return raw
          .map(_string)
          .where((item) => item.isNotEmpty)
          .toList(growable: false);
    }
    return const [];
  }
}
