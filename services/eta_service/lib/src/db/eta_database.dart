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
    _db.execute('''
      CREATE TABLE IF NOT EXISTS gps_positions (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        dedupe_key TEXT NOT NULL UNIQUE,
        vehicle_id TEXT NOT NULL,
        route_id TEXT NOT NULL,
        timestamp_ms INTEGER NOT NULL,
        lat REAL NOT NULL,
        lon REAL NOT NULL,
        speed REAL NOT NULL,
        azimuth INTEGER NOT NULL,
        gov_number TEXT NOT NULL,
        raw_json TEXT,
        inserted_at_ms INTEGER NOT NULL
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
    _db.execute(
      '''
      INSERT OR IGNORE INTO gps_positions (
        dedupe_key, vehicle_id, route_id, timestamp_ms, lat, lon, speed, azimuth,
        gov_number, raw_json, inserted_at_ms
      ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
    ''',
      [
        position.dedupeKey,
        position.vehicleId,
        position.routeId,
        position.timestampMs,
        position.lat,
        position.lon,
        position.speed,
        position.azimuth,
        position.govNumber,
        position.rawJson == null ? null : jsonEncode(position.rawJson),
        DateTime.now().millisecondsSinceEpoch,
      ],
    );
    final changed = (_db.select('SELECT changes() AS c').first['c'] as num)
        .toInt();
    return changed > 0;
  }

  int insertGpsPositions(Iterable<GpsPosition> positions) {
    var inserted = 0;
    _db.execute('BEGIN IMMEDIATE');
    final stmt = _db.prepare('''
      INSERT OR IGNORE INTO gps_positions (
        dedupe_key, vehicle_id, route_id, timestamp_ms, lat, lon, speed, azimuth,
        gov_number, raw_json, inserted_at_ms
      ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
    ''');
    try {
      for (final position in positions) {
        stmt.execute([
          position.dedupeKey,
          position.vehicleId,
          position.routeId,
          position.timestampMs,
          position.lat,
          position.lon,
          position.speed,
          position.azimuth,
          position.govNumber,
          position.rawJson == null ? null : jsonEncode(position.rawJson),
          DateTime.now().millisecondsSinceEpoch,
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
    final rows = _db.select(
      '''
      SELECT * FROM gps_positions
      $where
      ORDER BY timestamp_ms DESC
      LIMIT ?
    ''',
      [...args, limit],
    );
    return rows.map(_readGpsRow).toList(growable: false);
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
      'gps_positions': _db
          .select('SELECT * FROM gps_positions ORDER BY timestamp_ms DESC')
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
      lat: (row['lat'] as num).toDouble(),
      lon: (row['lon'] as num).toDouble(),
      speed: (row['speed'] as num).toDouble(),
      azimuth: (row['azimuth'] as num).toInt(),
      govNumber: row['gov_number'] as String,
      rawJson: row['raw_json'] == null
          ? null
          : Map<String, Object?>.from(
              jsonDecode(row['raw_json'] as String) as Map,
            ),
    );
  }
}
