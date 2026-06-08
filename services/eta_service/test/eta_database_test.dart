import 'package:eta_service/src/db/eta_database.dart';
import 'package:eta_service/src/domain/models.dart';
import 'package:test/test.dart';

void main() {
  test('migrates and deduplicates gps positions', () {
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
    expect(db.listGpsPositions(), hasLength(1));
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
}
