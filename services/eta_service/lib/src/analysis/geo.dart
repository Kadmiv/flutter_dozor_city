import 'dart:math' as math;

class GeoPoint {
  const GeoPoint({required this.lat, required this.lon});

  final double lat;
  final double lon;
}

class PolylineProjection {
  const PolylineProjection({
    required this.progressMeters,
    required this.distanceMeters,
    required this.segmentIndex,
  });

  final double progressMeters;
  final double distanceMeters;
  final int segmentIndex;
}

class PolylineMetric {
  PolylineMetric(List<GeoPoint> points)
    : points = points,
      cumulativeMeters = _buildCumulativeMeters(points);

  final List<GeoPoint> points;
  final List<double> cumulativeMeters;

  double get totalMeters =>
      cumulativeMeters.isEmpty ? 0 : cumulativeMeters.last;

  PolylineProjection project(GeoPoint point) {
    if (points.length < 2) {
      return const PolylineProjection(
        progressMeters: 0,
        distanceMeters: double.infinity,
        segmentIndex: 0,
      );
    }

    final originLat = points.first.lat;
    final originLon = points.first.lon;
    final px = _x(point.lon, originLat);
    final py = _y(point.lat);

    var bestDistance = double.infinity;
    var bestProgress = 0.0;
    var bestSegment = 0;

    for (var i = 0; i < points.length - 1; i++) {
      final a = points[i];
      final b = points[i + 1];
      final ax = _x(a.lon, originLat);
      final ay = _y(a.lat);
      final bx = _x(b.lon, originLat);
      final by = _y(b.lat);
      final dx = bx - ax;
      final dy = by - ay;
      final lengthSquared = dx * dx + dy * dy;
      if (lengthSquared == 0) {
        continue;
      }

      final rawT = ((px - ax) * dx + (py - ay) * dy) / lengthSquared;
      final t = rawT.clamp(0.0, 1.0);
      final projectedX = ax + dx * t;
      final projectedY = ay + dy * t;
      final distance = math.sqrt(
        math.pow(px - projectedX, 2) + math.pow(py - projectedY, 2),
      );
      if (distance < bestDistance) {
        bestDistance = distance;
        bestProgress =
            cumulativeMeters[i] + math.sqrt(lengthSquared) * t.toDouble();
        bestSegment = i;
      }
    }

    return PolylineProjection(
      progressMeters: bestProgress,
      distanceMeters: bestDistance,
      segmentIndex: bestSegment,
    );
  }
}

List<double> _buildCumulativeMeters(List<GeoPoint> points) {
  if (points.isEmpty) {
    return const [];
  }
  final cumulative = <double>[0.0];
  var total = 0.0;
  for (var i = 0; i < points.length - 1; i++) {
    total += haversineMeters(points[i], points[i + 1]);
    cumulative.add(total);
  }
  return cumulative;
}

double haversineMeters(GeoPoint a, GeoPoint b) {
  const earthRadiusMeters = 6371000.0;
  final lat1 = _degToRad(a.lat);
  final lat2 = _degToRad(b.lat);
  final deltaLat = _degToRad(b.lat - a.lat);
  final deltaLon = _degToRad(b.lon - a.lon);
  final sinLat = math.sin(deltaLat / 2);
  final sinLon = math.sin(deltaLon / 2);
  final h = sinLat * sinLat + math.cos(lat1) * math.cos(lat2) * sinLon * sinLon;
  return 2 * earthRadiusMeters * math.asin(math.sqrt(h));
}

double _x(double lon, double originLat) {
  const earthRadiusMeters = 6371000.0;
  return _degToRad(lon) * earthRadiusMeters * math.cos(_degToRad(originLat));
}

double _y(double lat) {
  const earthRadiusMeters = 6371000.0;
  return _degToRad(lat) * earthRadiusMeters;
}

double _degToRad(double deg) => deg * math.pi / 180.0;
