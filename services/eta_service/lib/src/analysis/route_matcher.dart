import '../domain/models.dart';
import 'geo.dart';

class RouteMatch {
  const RouteMatch({
    required this.vehicleId,
    required this.routeId,
    required this.timestampMs,
    required this.progressMeters,
    required this.distanceToRouteMeters,
    required this.segmentIndex,
    required this.segmentId,
    required this.fromStopId,
    required this.toStopId,
  });

  final String vehicleId;
  final String routeId;
  final int timestampMs;
  final double progressMeters;
  final double distanceToRouteMeters;
  final int segmentIndex;
  final String segmentId;
  final String fromStopId;
  final String toStopId;
}

class RouteMatcher {
  RouteMatcher({this.maxDistanceMeters = 120});

  final double maxDistanceMeters;

  RouteMatch? match(RouteTrackData track, GpsPosition position) {
    final geometry = _buildGeometry(track);
    if (geometry == null || geometry.stops.length < 2) {
      return null;
    }

    final projection = geometry.metric.project(
      GeoPoint(lat: position.lat, lon: position.lon),
    );
    if (projection.distanceMeters > maxDistanceMeters) {
      return null;
    }

    final segmentIndex = _segmentIndexForProgress(
      projection.progressMeters,
      geometry.stops,
    );
    if (segmentIndex == null) {
      return null;
    }
    final fromStop = geometry.stops[segmentIndex];
    final toStop = geometry.stops[segmentIndex + 1];

    return RouteMatch(
      vehicleId: position.vehicleId,
      routeId: track.route.id,
      timestampMs: position.timestampMs,
      progressMeters: projection.progressMeters,
      distanceToRouteMeters: projection.distanceMeters,
      segmentIndex: segmentIndex,
      segmentId:
          '${track.route.id}:${fromStop.stop.stopId}:${toStop.stop.stopId}',
      fromStopId: fromStop.stop.stopId,
      toStopId: toStop.stop.stopId,
    );
  }

  _RouteGeometry? _buildGeometry(RouteTrackData track) {
    final polylinePoints = <GeoPoint>[];
    for (final segment in track.polylineSegments) {
      for (final point in segment) {
        final lat = (point['lat'] as num?)?.toDouble();
        final lon = (point['lon'] as num?)?.toDouble();
        if (lat == null || lon == null) {
          continue;
        }
        polylinePoints.add(GeoPoint(lat: lat, lon: lon));
      }
    }
    if (polylinePoints.length < 2) {
      return null;
    }

    final metric = PolylineMetric(polylinePoints);
    final orderedStops = track.stops.toList(growable: false)
      ..sort((a, b) => a.stopOrder.compareTo(b.stopOrder));
    final stopProgresses = <_StopProgress>[];
    double lastProgress = -1;
    for (final stop in orderedStops) {
      final projection = metric.project(GeoPoint(lat: stop.lat, lon: stop.lon));
      var progress = projection.progressMeters;
      if (progress <= lastProgress) {
        progress = lastProgress + 0.1;
      }
      stopProgresses.add(_StopProgress(stop: stop, progressMeters: progress));
      lastProgress = progress;
    }

    return _RouteGeometry(metric: metric, stops: stopProgresses);
  }

  int? _segmentIndexForProgress(
    double progressMeters,
    List<_StopProgress> stops,
  ) {
    if (stops.length < 2) {
      return null;
    }
    if (progressMeters <= stops.first.progressMeters) {
      return 0;
    }
    if (progressMeters >= stops.last.progressMeters) {
      return stops.length - 2;
    }
    for (var i = 0; i < stops.length - 1; i++) {
      final current = stops[i];
      final next = stops[i + 1];
      if (progressMeters >= current.progressMeters &&
          progressMeters < next.progressMeters) {
        return i;
      }
    }
    return stops.length - 2;
  }
}

class _RouteGeometry {
  const _RouteGeometry({required this.metric, required this.stops});

  final PolylineMetric metric;
  final List<_StopProgress> stops;
}

class _StopProgress {
  const _StopProgress({required this.stop, required this.progressMeters});

  final RouteTrackStop stop;
  final double progressMeters;
}
