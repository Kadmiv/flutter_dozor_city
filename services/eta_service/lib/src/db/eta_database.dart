import 'dart:io';
import 'dart:convert';

import 'package:path/path.dart' as p;
import 'package:sqlite3/sqlite3.dart';

import '../domain/models.dart';

class EtaDatabase {
  EtaDatabase(this._db);

  final Database _db;

  static EtaDatabase open(String path) {
    if (path != ':memory:') {
      Directory(p.dirname(path)).createSync(recursive: true);
    }
    final db = sqlite3.open(path);
    final instance = EtaDatabase(db);
    instance.migrate();
    return instance;
  }

  void migrate() {
    if (_needsGpsReset()) {
      _db.execute('DROP TABLE IF EXISTS gps_positions');
      _db.execute('DROP TABLE IF EXISTS segment_events');
      _db.execute('DROP TABLE IF EXISTS aggregated_segment_stats');
    }

    _db.execute('''
      CREATE TABLE IF NOT EXISTS gps_positions (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        vehicle_id TEXT NOT NULL,
        route_id TEXT NOT NULL,
        timestamp_ms INTEGER NOT NULL,
        lat_e6 INTEGER NOT NULL,
        lon_e6 INTEGER NOT NULL,
        inserted_at_ms INTEGER NOT NULL,
        UNIQUE(vehicle_id, route_id, timestamp_ms, lat_e6, lon_e6)
      );
    ''');

    _db.execute('''
      CREATE TABLE IF NOT EXISTS routes (
        id TEXT PRIMARY KEY,
        short_name TEXT NOT NULL,
        title TEXT NOT NULL,
        transport_type INTEGER NOT NULL,
        sort_order INTEGER NOT NULL,
        is_circle INTEGER NOT NULL
      );
    ''');

    _db.execute('''
      CREATE TABLE IF NOT EXISTS stops (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        lat REAL NOT NULL,
        lon REAL NOT NULL,
        number INTEGER NOT NULL
      );
    ''');

    _db.execute('''
      CREATE TABLE IF NOT EXISTS route_stops (
        route_id TEXT NOT NULL,
        stop_id TEXT NOT NULL,
        stop_order INTEGER NOT NULL,
        status INTEGER NOT NULL,
        times_json TEXT NOT NULL,
        PRIMARY KEY (route_id, stop_id)
      );
    ''');

    _db.execute('''
      CREATE TABLE IF NOT EXISTS route_polylines (
        route_id TEXT NOT NULL,
        segment_index INTEGER NOT NULL,
        points_json TEXT NOT NULL,
        PRIMARY KEY (route_id, segment_index)
      );
    ''');

    _db.execute('''
      CREATE TABLE IF NOT EXISTS segment_events (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        vehicle_id TEXT NOT NULL,
        segment_id TEXT NOT NULL,
        started_at_ms INTEGER NOT NULL,
        finished_at_ms INTEGER NOT NULL,
        duration_sec INTEGER NOT NULL
      );
    ''');

    _db.execute('''
      CREATE TABLE IF NOT EXISTS aggregated_segment_stats (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        segment_id TEXT NOT NULL,
        day_type TEXT NOT NULL,
        bucket_start_min INTEGER NOT NULL,
        bucket_end_min INTEGER NOT NULL,
        sample_count INTEGER NOT NULL,
        average_duration_sec REAL NOT NULL
      );
    ''');
  }

  void close() => _db.dispose();

  bool insertGpsPosition(GpsPosition position) {
    return insertGpsPositions([position]) > 0;
  }

  int insertGpsPositions(Iterable<GpsPosition> positions) {
    var inserted = 0;
    _db.execute('BEGIN IMMEDIATE');
    final stmt = _db.prepare('''
      INSERT OR IGNORE INTO gps_positions (
        vehicle_id, route_id, timestamp_ms, lat_e6, lon_e6, inserted_at_ms
      ) VALUES (?, ?, ?, ?, ?, ?)
    ''');
    try {
      final insertedAtMs = DateTime.now().millisecondsSinceEpoch;
      for (final position in positions) {
        stmt.execute([
          position.vehicleId,
          position.routeId,
          position.timestampMs,
          _toE6(position.lat),
          _toE6(position.lon),
          insertedAtMs,
        ]);
        final changed = (_db.select('SELECT changes() AS c').first['c'] as num)
            .toInt();
        if (changed > 0) {
          inserted++;
        }
      }
      _db.execute('COMMIT');
    } catch (_) {
      _db.execute('ROLLBACK');
      rethrow;
    } finally {
      stmt.dispose();
    }
    return inserted;
  }

  List<GpsPosition> listGpsPositions({
    String? vehicleId,
    String? routeId,
    int limit = 100,
    bool ascending = false,
  }) {
    final clauses = <String>[];
    final args = <Object?>[];
    if (vehicleId != null && vehicleId.isNotEmpty) {
      clauses.add('vehicle_id = ?');
      args.add(vehicleId);
    }
    if (routeId != null && routeId.isNotEmpty) {
      clauses.add('route_id = ?');
      args.add(routeId);
    }
    final where = clauses.isEmpty ? '' : 'WHERE ${clauses.join(' AND ')}';
    final orderBy = ascending ? 'ASC' : 'DESC';
    final rows = _db.select(
      '''
      SELECT vehicle_id, route_id, timestamp_ms, lat_e6, lon_e6, inserted_at_ms
      FROM gps_positions
      $where
      ORDER BY timestamp_ms $orderBy
      LIMIT ?
    ''',
      [...args, limit],
    );
    return rows.map(_readGpsRow).toList(growable: false);
  }

  List<String> getRouteIdsWithGpsData() {
    final rows = _db.select(
      'SELECT DISTINCT route_id FROM gps_positions ORDER BY route_id',
    );
    return rows.map((row) => row['route_id'] as String).toList(growable: false);
  }

  List<String> getRouteIds() {
    final rows = _db.select('SELECT id FROM routes ORDER BY sort_order');
    return rows.map((row) => row['id'] as String).toList(growable: false);
  }

  RouteTrackData? loadRouteTrack(String routeId) {
    final routeRows = _db.select('SELECT * FROM routes WHERE id = ? LIMIT 1', [
      routeId,
    ]);
    if (routeRows.isEmpty) {
      return null;
    }
    final route = _readRoute(routeRows.first);
    final stopRows = _db.select(
      '''
      SELECT
        rs.stop_id,
        rs.stop_order,
        rs.status,
        rs.times_json,
        s.name,
        s.lat,
        s.lon,
        s.number
      FROM route_stops rs
      JOIN stops s ON s.id = rs.stop_id
      WHERE rs.route_id = ?
      ORDER BY rs.stop_order
    ''',
      [routeId],
    );
    final stops = stopRows.map(_readRouteTrackStop).toList(growable: false);
    final polylineRows = _db.select(
      '''
      SELECT segment_index, points_json
      FROM route_polylines
      WHERE route_id = ?
      ORDER BY segment_index
    ''',
      [routeId],
    );
    final segments = polylineRows
        .map(_readRoutePolylineSegment)
        .toList(growable: false);
    return RouteTrackData(
      route: route,
      stops: stops,
      polylineSegments: segments,
    );
  }

  List<SegmentEventRecord> getSegmentEvents({String? routeId}) {
    final clauses = <String>[];
    final args = <Object?>[];
    if (routeId != null && routeId.isNotEmpty) {
      clauses.add('segment_id LIKE ?');
      args.add('$routeId:%');
    }
    final where = clauses.isEmpty ? '' : 'WHERE ${clauses.join(' AND ')}';
    final rows = _db.select('''
      SELECT * FROM segment_events
      $where
      ORDER BY started_at_ms ASC
    ''', args);
    return rows
        .map(
          (row) => SegmentEventRecord(
            vehicleId: row['vehicle_id'] as String,
            segmentId: row['segment_id'] as String,
            startedAtMs: (row['started_at_ms'] as num).toInt(),
            finishedAtMs: (row['finished_at_ms'] as num).toInt(),
            durationSec: (row['duration_sec'] as num).toInt(),
          ),
        )
        .toList(growable: false);
  }

  List<AggregatedSegmentStatRecord> getAggregatedSegmentStats({
    String? routeId,
  }) {
    final clauses = <String>[];
    final args = <Object?>[];
    if (routeId != null && routeId.isNotEmpty) {
      clauses.add('segment_id LIKE ?');
      args.add('$routeId:%');
    }
    final where = clauses.isEmpty ? '' : 'WHERE ${clauses.join(' AND ')}';
    final rows = _db.select('''
      SELECT * FROM aggregated_segment_stats
      $where
      ORDER BY segment_id, bucket_start_min
    ''', args);
    return rows
        .map(
          (row) => AggregatedSegmentStatRecord(
            segmentId: row['segment_id'] as String,
            dayType: row['day_type'] as String,
            bucketStartMin: (row['bucket_start_min'] as num).toInt(),
            bucketEndMin: (row['bucket_end_min'] as num).toInt(),
            sampleCount: (row['sample_count'] as num).toInt(),
            averageDurationSec: (row['average_duration_sec'] as num).toDouble(),
          ),
        )
        .toList(growable: false);
  }

  void deleteAnalysisForRoute(String routeId) {
    _db.execute('DELETE FROM segment_events WHERE segment_id LIKE ?', [
      '$routeId:%',
    ]);
    _db.execute(
      'DELETE FROM aggregated_segment_stats WHERE segment_id LIKE ?',
      ['$routeId:%'],
    );
  }

  void insertSegmentEvents(List<SegmentEventRecord> events) {
    if (events.isEmpty) {
      return;
    }
    _db.execute('BEGIN IMMEDIATE');
    final stmt = _db.prepare('''
      INSERT INTO segment_events (
        vehicle_id, segment_id, started_at_ms, finished_at_ms, duration_sec
      ) VALUES (?, ?, ?, ?, ?)
    ''');
    try {
      for (final event in events) {
        stmt.execute([
          event.vehicleId,
          event.segmentId,
          event.startedAtMs,
          event.finishedAtMs,
          event.durationSec,
        ]);
      }
      _db.execute('COMMIT');
    } catch (_) {
      _db.execute('ROLLBACK');
      rethrow;
    } finally {
      stmt.dispose();
    }
  }

  void replaceAggregatedSegmentStats(List<AggregatedSegmentStatRecord> stats) {
    if (stats.isEmpty) {
      return;
    }
    _db.execute('BEGIN IMMEDIATE');
    final stmt = _db.prepare('''
      INSERT INTO aggregated_segment_stats (
        segment_id, day_type, bucket_start_min, bucket_end_min, sample_count,
        average_duration_sec
      ) VALUES (?, ?, ?, ?, ?, ?)
    ''');
    try {
      for (final stat in stats) {
        stmt.execute([
          stat.segmentId,
          stat.dayType,
          stat.bucketStartMin,
          stat.bucketEndMin,
          stat.sampleCount,
          stat.averageDurationSec,
        ]);
      }
      _db.execute('COMMIT');
    } catch (_) {
      _db.execute('ROLLBACK');
      rethrow;
    } finally {
      stmt.dispose();
    }
  }

  void replaceSnapshot(BatumiSnapshot snapshot) {
    _db.execute('BEGIN IMMEDIATE');
    final routeStmt = _db.prepare('''
      INSERT INTO routes (id, short_name, title, transport_type, sort_order, is_circle)
      VALUES (?, ?, ?, ?, ?, ?)
    ''');
    final stopStmt = _db.prepare('''
      INSERT INTO stops (id, name, lat, lon, number) VALUES (?, ?, ?, ?, ?)
    ''');
    final routeStopStmt = _db.prepare('''
      INSERT INTO route_stops (route_id, stop_id, stop_order, status, times_json)
      VALUES (?, ?, ?, ?, ?)
    ''');
    final polylineStmt = _db.prepare('''
      INSERT INTO route_polylines (route_id, segment_index, points_json)
      VALUES (?, ?, ?)
    ''');

    try {
      _db.execute('DELETE FROM routes');
      _db.execute('DELETE FROM stops');
      _db.execute('DELETE FROM route_stops');
      _db.execute('DELETE FROM route_polylines');

      for (final route in snapshot.routes) {
        routeStmt.execute([
          route.id,
          route.shortName,
          route.title,
          route.transportType,
          route.sortOrder,
          route.isCircle ? 1 : 0,
        ]);
      }
      for (final stop in snapshot.stops) {
        stopStmt.execute([stop.id, stop.name, stop.lat, stop.lon, stop.number]);
      }
      for (final item in snapshot.routeStops) {
        routeStopStmt.execute([
          item.routeId,
          item.stopId,
          item.stopOrder,
          item.status,
          jsonEncode(item.times),
        ]);
      }
      for (final item in snapshot.routePolylines) {
        polylineStmt.execute([
          item.routeId,
          item.segmentIndex,
          item.pointsJson,
        ]);
      }
      _db.execute('COMMIT');
    } catch (_) {
      _db.execute('ROLLBACK');
      rethrow;
    } finally {
      routeStmt.dispose();
      stopStmt.dispose();
      routeStopStmt.dispose();
      polylineStmt.dispose();
    }
  }

  Map<String, Object?> snapshotJson() {
    return {
      'routes': _db
          .select('SELECT * FROM routes ORDER BY sort_order')
          .map((row) => Map<String, Object?>.from(row))
          .toList(growable: false),
      'stops': _db
          .select('SELECT * FROM stops ORDER BY number')
          .map((row) => Map<String, Object?>.from(row))
          .toList(growable: false),
      'route_stops': _db
          .select('SELECT * FROM route_stops ORDER BY route_id, stop_order')
          .map((row) => Map<String, Object?>.from(row))
          .toList(growable: false),
      'route_polylines': _db
          .select(
            'SELECT * FROM route_polylines ORDER BY route_id, segment_index',
          )
          .map((row) => Map<String, Object?>.from(row))
          .toList(growable: false),
      'segment_events': _db
          .select('SELECT * FROM segment_events ORDER BY started_at_ms DESC')
          .map((row) => Map<String, Object?>.from(row))
          .toList(growable: false),
      'aggregated_segment_stats': _db
          .select(
            'SELECT * FROM aggregated_segment_stats ORDER BY segment_id, bucket_start_min',
          )
          .map((row) => Map<String, Object?>.from(row))
          .toList(growable: false),
    };
  }

  GpsPosition _readGpsRow(Row row) {
    return GpsPosition(
      vehicleId: row['vehicle_id'] as String,
      routeId: row['route_id'] as String,
      timestampMs: (row['timestamp_ms'] as num).toInt(),
      lat: _fromE6(row['lat_e6']),
      lon: _fromE6(row['lon_e6']),
      speed: 0,
      azimuth: 0,
      govNumber: '',
    );
  }

  RouteRecord _readRoute(Row row) {
    return RouteRecord(
      id: row['id'] as String,
      shortName: row['short_name'] as String,
      title: row['title'] as String,
      transportType: (row['transport_type'] as num).toInt(),
      sortOrder: (row['sort_order'] as num).toInt(),
      isCircle: (row['is_circle'] as num).toInt() != 0,
    );
  }

  RouteTrackStop _readRouteTrackStop(Row row) {
    return RouteTrackStop(
      stopId: row['stop_id'] as String,
      name: row['name'] as String,
      lat: (row['lat'] as num).toDouble(),
      lon: (row['lon'] as num).toDouble(),
      number: (row['number'] as num).toInt(),
      stopOrder: (row['stop_order'] as num).toInt(),
      status: (row['status'] as num).toInt(),
      times: _readStringList(row['times_json']),
    );
  }

  List<Map<String, Object?>> _readRoutePolylineSegment(Row row) {
    final raw = row['points_json'];
    if (raw is! String || raw.isEmpty) {
      return const [];
    }
    final decoded = jsonDecode(raw);
    if (decoded is! List) {
      return const [];
    }
    return decoded
        .whereType<Map>()
        .map(
          (point) =>
              point.map((key, value) => MapEntry('$key', value as Object?)),
        )
        .toList(growable: false);
  }

  List<String> _readStringList(Object? raw) {
    if (raw is! String || raw.isEmpty) {
      return const [];
    }
    final decoded = jsonDecode(raw);
    if (decoded is! List) {
      return const [];
    }
    return decoded.map((item) => '$item').toList(growable: false);
  }

  bool _needsGpsReset() {
    final rows = _db.select(
      "SELECT name FROM sqlite_master WHERE type = 'table' AND name = 'gps_positions' LIMIT 1",
    );
    if (rows.isEmpty) {
      return false;
    }
    final columns = _db.select('PRAGMA table_info(gps_positions)');
    final actual = columns.map((row) => row['name'] as String).toSet();
    const expected = {
      'id',
      'vehicle_id',
      'route_id',
      'timestamp_ms',
      'lat_e6',
      'lon_e6',
      'inserted_at_ms',
    };
    return actual.length != expected.length || !actual.containsAll(expected);
  }

  int _toE6(double value) => (value * 1000000).round();

  double _fromE6(Object? raw) {
    if (raw is num) {
      return raw.toDouble() / 1000000.0;
    }
    return double.tryParse('$raw')?.toDouble() ?? 0.0;
  }
}
