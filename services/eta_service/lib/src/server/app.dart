import 'dart:convert';

import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';

import '../db/eta_database.dart';
import '../domain/models.dart';
import '../logging/service_logger.dart';

class EtaHttpApp {
  EtaHttpApp(this._database, {ServiceLogger? logger})
    : _logger = logger ?? const ServiceLogger();

  final EtaDatabase _database;
  final ServiceLogger _logger;

  Handler build() {
    final router = Router();
    router.get('/', _index);
    router.get('/health', _health);
    router.post('/gps', _postGps);
    router.post('/gps/batch', _postGpsBatch);
    router.get('/gps', _getGps);
    return const Pipeline()
        .addMiddleware(logRequests())
        .addHandler(router.call);
  }

  Response _index(Request request) {
    _logger.info('Index request');
    return Response.ok(
      jsonEncode({
        'service': 'eta_service',
        'status': 'ok',
        'endpoints': ['/health', '/gps', '/gps/batch'],
      }),
      headers: _jsonHeaders,
    );
  }

  Response _health(Request request) {
    _logger.info('Health check request');
    return Response.ok(jsonEncode({'ok': true}), headers: _jsonHeaders);
  }

  Future<Response> _postGps(Request request) async {
    try {
      final payload = await request.readAsString();
      _logger.info('Received GPS payload (${payload.length} bytes)');
      final json = jsonDecode(payload);
      if (json is! Map) {
        return _badRequest('Expected JSON object');
      }
      final position = GpsPosition.fromJson(_asMap(json));
      if (!_isValid(position)) {
        _logger.warn('Rejected GPS payload: missing required fields');
        return _badRequest('Missing required fields');
      }
      _logger.info(
        'Saving GPS position vehicle=${position.vehicleId}, route=${position.routeId}, lat=${position.lat}, lon=${position.lon}, timestamp=${position.timestampMs}',
      );
      final inserted = _database.insertGpsPosition(position);
      _logger.info(
        inserted
            ? 'Inserted new GPS position for ${position.vehicleId}'
            : 'Skipped duplicate GPS position for ${position.vehicleId}',
      );
      return Response.ok(
        jsonEncode({'inserted': inserted}),
        headers: _jsonHeaders,
      );
    } catch (_) {
      return _badRequest('Invalid JSON payload');
    }
  }

  Future<Response> _postGpsBatch(Request request) async {
    try {
      final payload = await request.readAsString();
      _logger.info('Received GPS batch payload (${payload.length} bytes)');
      final json = jsonDecode(payload);
      if (json is! List) {
        return _badRequest('Expected JSON array');
      }
      final positions = <GpsPosition>[];
      for (final item in json) {
        if (item is Map) {
          final position = GpsPosition.fromJson(_asMap(item));
          if (_isValid(position)) {
            positions.add(position);
          }
        }
      }
      _logger.info('Saving ${positions.length} GPS positions from batch');
      final inserted = _database.insertGpsPositions(positions);
      _logger.info('Inserted $inserted new GPS positions from batch');
      return Response.ok(
        jsonEncode({'inserted': inserted, 'received': positions.length}),
        headers: _jsonHeaders,
      );
    } catch (_) {
      return _badRequest('Invalid JSON payload');
    }
  }

  Response _getGps(Request request) {
    final vehicleId = request.url.queryParameters['vehicleId'];
    final routeId = request.url.queryParameters['routeId'];
    final limit =
        int.tryParse(request.url.queryParameters['limit'] ?? '100') ?? 100;
    _logger.info(
      'Reading GPS positions vehicleId=${vehicleId ?? '-'} routeId=${routeId ?? '-'} limit=$limit',
    );
    final rows = _database.listGpsPositions(
      vehicleId: vehicleId,
      routeId: routeId,
      limit: limit.clamp(1, 1000),
    );
    return Response.ok(
      jsonEncode({
        'items': rows.map((row) => row.toJson()).toList(growable: false),
      }),
      headers: _jsonHeaders,
    );
  }

  Response _badRequest(String message) {
    return Response(
      400,
      body: jsonEncode({'error': message}),
      headers: _jsonHeaders,
    );
  }

  Map<String, Object?> _asMap(Map raw) {
    return raw.map((key, value) => MapEntry('$key', value as Object?));
  }

  bool _isValid(GpsPosition position) {
    return position.vehicleId.isNotEmpty &&
        position.routeId.isNotEmpty &&
        position.timestampMs > 0 &&
        position.lat != 0 &&
        position.lon != 0;
  }
}

const _jsonHeaders = {'content-type': 'application/json; charset=utf-8'};
