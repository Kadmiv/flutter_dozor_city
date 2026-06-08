import 'dart:io';

import 'package:eta_service/src/db/eta_database.dart';
import 'package:eta_service/src/domain/models.dart';
import 'package:sqlite3/sqlite3.dart';
import 'package:test/test.dart';

void main() {
  test('migrates and deduplicates compact gps positions', () {
    final db = EtaDatabase.open(':memory:');
    addTearDown(db.close);

    final position = GpsPosition(
      vehicleId: 'v1',
      routeId: 'r1',
      timestampMs: 1,
      lat: 1.0,
      lon: 2.0,
      speed: 10,
      azimuth: 0,
      govNumber: 'GN',
    );

    expect(db.insertGpsPosition(position), isTrue);
    expect(db.insertGpsPosition(position), isFalse);
    final rows = db.listGpsPositions();
    expect(rows, hasLength(1));
    expect(rows.single.lat, 1.0);
    expect(rows.single.lon, 2.0);
    expect(db.snapshotJson().containsKey('gps_positions'), isFalse);
  });

  test('stores batumi snapshot data', () {
    final db = EtaDatabase.open(':memory:');
    addTearDown(db.close);

    db.replaceSnapshot(
      const BatumiSnapshot(
        routes: [
          RouteRecord(
            id: 'r1',
            shortName: '1',
            title: 'Route 1',
            transportType: 0,
            sortOrder: 10,
            isCircle: false,
          ),
        ],
        stops: [
          StopRecord(
            id: 's1',
            name: 'Stop 1',
            lat: 41.6,
            lon: 41.61,
            number: 1,
          ),
        ],
        routeStops: [
          RouteStopRecord(
            routeId: 'r1',
            stopId: 's1',
            stopOrder: 1,
            status: 1,
            times: ['07:00'],
          ),
        ],
        routePolylines: [
          RoutePolylineRecord(
            routeId: 'r1',
            segmentIndex: 0,
            points: [
              {'lat': 41.6, 'lon': 41.61},
            ],
          ),
        ],
      ),
    );

    final snapshot = db.snapshotJson();
    expect(snapshot['routes'], hasLength(1));
    expect(snapshot['stops'], hasLength(1));
    expect(snapshot['route_stops'], hasLength(1));
    expect(snapshot['route_polylines'], hasLength(1));
  });

  test('recreates legacy gps schema as compact storage', () {
    final dir = Directory.systemTemp.createTempSync('eta-service-legacy-');
    addTearDown(() => dir.deleteSync(recursive: true));

    final dbPath = '${dir.path}/service.db';
    final raw = sqlite3.open(dbPath);
    raw.execute('''
      CREATE TABLE gps_positions (
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
    raw.execute('''
      CREATE TABLE segment_events (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        vehicle_id TEXT NOT NULL,
        segment_id TEXT NOT NULL,
        started_at_ms INTEGER NOT NULL,
        finished_at_ms INTEGER NOT NULL,
        duration_sec INTEGER NOT NULL
      );
    ''');
    raw.execute('''
      CREATE TABLE aggregated_segment_stats (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        segment_id TEXT NOT NULL,
        day_type TEXT NOT NULL,
        bucket_start_min INTEGER NOT NULL,
        bucket_end_min INTEGER NOT NULL,
        sample_count INTEGER NOT NULL,
        average_duration_sec REAL NOT NULL
      );
    ''');
    raw.execute('''
      INSERT INTO gps_positions (
        dedupe_key, vehicle_id, route_id, timestamp_ms, lat, lon, speed, azimuth,
        gov_number, raw_json, inserted_at_ms
      ) VALUES ('k1', 'v1', 'r1', 1, 1.0, 2.0, 0, 0, 'GN', '{"x":1}', 1);
    ''');
    raw.dispose();

    final db = EtaDatabase.open(dbPath);
    addTearDown(db.close);

    expect(db.listGpsPositions(), isEmpty);
    expect(
      db.insertGpsPosition(
        const GpsPosition(
          vehicleId: 'v2',
          routeId: 'r2',
          timestampMs: 2,
          lat: 3.0,
          lon: 4.0,
          speed: 0,
          azimuth: 0,
          govNumber: 'GN2',
        ),
      ),
      isTrue,
    );

    final rows = db.listGpsPositions();
    expect(rows, hasLength(1));
    expect(rows.single.vehicleId, 'v2');
    expect(rows.single.lat, 3.0);
    expect(rows.single.lon, 4.0);
  });
}
