import 'package:eta_service/src/domain/models.dart';

const sampleRouteId = 'r1';
const sampleStop1Id = 's1';
const sampleStop2Id = 's2';
const sampleStop3Id = 's3';

RouteTrackData buildSampleRouteTrack() {
  return RouteTrackData(
    route: const RouteRecord(
      id: sampleRouteId,
      shortName: '1',
      title: 'Route 1',
      transportType: 0,
      sortOrder: 1,
      isCircle: false,
    ),
    stops: const [
      RouteTrackStop(
        stopId: sampleStop1Id,
        name: 'Stop 1',
        lat: 41.0,
        lon: 41.0,
        number: 1,
        stopOrder: 1,
        status: 1,
        times: ['07:00'],
      ),
      RouteTrackStop(
        stopId: sampleStop2Id,
        name: 'Stop 2',
        lat: 41.0,
        lon: 41.01,
        number: 2,
        stopOrder: 2,
        status: 1,
        times: ['07:05'],
      ),
      RouteTrackStop(
        stopId: sampleStop3Id,
        name: 'Stop 3',
        lat: 41.0,
        lon: 41.02,
        number: 3,
        stopOrder: 3,
        status: 1,
        times: ['07:10'],
      ),
    ],
    polylineSegments: const [
      [
        {'lat': 41.0, 'lon': 41.0},
        {'lat': 41.0, 'lon': 41.005},
        {'lat': 41.0, 'lon': 41.01},
        {'lat': 41.0, 'lon': 41.015},
        {'lat': 41.0, 'lon': 41.02},
      ],
    ],
  );
}

BatumiSnapshot buildSampleSnapshot() {
  final track = buildSampleRouteTrack();
  return BatumiSnapshot(
    routes: [track.route],
    stops: track.stops
        .map(
          (stop) => StopRecord(
            id: stop.stopId,
            name: stop.name,
            lat: stop.lat,
            lon: stop.lon,
            number: stop.number,
          ),
        )
        .toList(growable: false),
    routeStops: track.stops
        .map(
          (stop) => RouteStopRecord(
            routeId: track.route.id,
            stopId: stop.stopId,
            stopOrder: stop.stopOrder,
            status: stop.status,
            times: stop.times,
          ),
        )
        .toList(growable: false),
    routePolylines: [
      RoutePolylineRecord(
        routeId: track.route.id,
        segmentIndex: 0,
        points: track.polylineSegments.first,
      ),
    ],
  );
}

List<GpsPosition> buildForwardSamplePositions() {
  return [
    _gps('v1', sampleRouteId, 1, 41.0, 41.003),
    _gps('v1', sampleRouteId, 61, 41.0, 41.008),
    _gps('v1', sampleRouteId, 121, 41.0, 41.012),
    _gps('v1', sampleRouteId, 181, 41.0, 41.018),
  ];
}

List<GpsPosition> buildReverseJumpPositions() {
  return [
    _gps('v1', sampleRouteId, 1, 41.0, 41.003),
    _gps('v1', sampleRouteId, 61, 41.0, 41.012),
    _gps('v1', sampleRouteId, 121, 41.0, 41.004),
    _gps('v1', sampleRouteId, 181, 41.0, 41.018),
  ];
}

GpsPosition buildFarAwayPosition() {
  return _gps('v1', sampleRouteId, 1, 42.0, 42.0);
}

GpsPosition _gps(
  String vehicleId,
  String routeId,
  int timestampSec,
  double lat,
  double lon,
) {
  return GpsPosition(
    vehicleId: vehicleId,
    routeId: routeId,
    timestampMs: timestampSec * 1000,
    lat: lat,
    lon: lon,
    speed: 10,
    azimuth: 0,
    govNumber: vehicleId,
  );
}
