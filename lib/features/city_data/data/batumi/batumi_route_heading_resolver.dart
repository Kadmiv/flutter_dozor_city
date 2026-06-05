import 'dart:math' as math;

import 'package:flutter_dozor_city/core/domain/entities/app_lat_lng.dart';
import 'package:flutter_dozor_city/features/city_data/data/batumi/batumi_bus_location_dto.dart';
import 'package:flutter_dozor_city/features/city_data/data/batumi/batumi_db_data_dto.dart';
import 'package:flutter_dozor_city/features/city_data/data/batumi/batumi_points_between_stations_dto.dart';

class BatumiRouteHeadingResolver {
  const BatumiRouteHeadingResolver();

  int resolveAzimuth({
    required String routeId,
    required BatumiBusLocationDto location,
    required BatumiDbDataDto snapshot,
    required BatumiPointsBetweenStationsDto points,
  }) {
    final position = AppLatLng(lat: location.lat, lng: location.lon);
    final knownStatusPath = _directionPath(
      routeId: routeId,
      status: location.status,
      snapshot: snapshot,
      points: points,
    );
    if (knownStatusPath.length > 1 && _isKnownStatus(location.status)) {
      final segment = _bestSegment([knownStatusPath], position);
      return segment?.bearing ?? 0;
    }

    final candidates = <List<AppLatLng>>[];
    final firstDirectionPath = _directionPath(
      routeId: routeId,
      status: 1,
      snapshot: snapshot,
      points: points,
    );
    if (firstDirectionPath.length > 1) {
      candidates.add(firstDirectionPath);
    }
    final secondDirectionPath = _directionPath(
      routeId: routeId,
      status: 2,
      snapshot: snapshot,
      points: points,
    );
    if (secondDirectionPath.length > 1) {
      candidates.add(secondDirectionPath);
    }
    final fullPath = _buildFullPath(
      routeId: routeId,
      snapshot: snapshot,
      points: points,
    );
    if (fullPath.length > 1) {
      candidates.add(fullPath);
    }

    if (candidates.isEmpty && knownStatusPath.length > 1) {
      final segment = _bestSegment([knownStatusPath], position);
      return segment?.bearing ?? 0;
    }

    final best = _bestSegment(candidates, position);
    if (best == null) {
      return 0;
    }
    return best.bearing;
  }

  List<AppLatLng> _directionPath({
    required String routeId,
    required int status,
    required BatumiDbDataDto snapshot,
    required BatumiPointsBetweenStationsDto points,
  }) {
    final routeStops = snapshot.busStops.values
        .where((stop) => stop.routes[routeId]?.status == status)
        .toList(growable: false)
      ..sort((a, b) {
        final left = a.routes[routeId]?.order ?? 0;
        final right = b.routes[routeId]?.order ?? 0;
        return left.compareTo(right);
      });
    return _buildPathFromStops(
      routeId: routeId,
      routeStops: routeStops,
      points: points,
    );
  }

  List<AppLatLng> _buildFullPath({
    required String routeId,
    required BatumiDbDataDto snapshot,
    required BatumiPointsBetweenStationsDto points,
  }) {
    final routeStops = snapshot.busStops.values
        .where((stop) => stop.routes.containsKey(routeId))
        .toList(growable: false)
      ..sort((a, b) {
        final left = a.routes[routeId]?.order ?? 0;
        final right = b.routes[routeId]?.order ?? 0;
        return left.compareTo(right);
      });
    return _buildPathFromStops(
      routeId: routeId,
      routeStops: routeStops,
      points: points,
    );
  }

  List<AppLatLng> _buildPathFromStops({
    required String routeId,
    required List<BatumiBusStopDto> routeStops,
    required BatumiPointsBetweenStationsDto points,
  }) {
    final routePointsByStop = points.data[routeId];
    if (routePointsByStop == null) {
      return const [];
    }
    final path = <AppLatLng>[];
    final orderedStopIds = routeStops.isNotEmpty
        ? routeStops.map((stop) => stop.id).toList(growable: false)
        : routePointsByStop.keys.toList(growable: false);
    for (final stopId in orderedStopIds) {
      final stopPoints = routePointsByStop[stopId];
      if (stopPoints == null || stopPoints.isEmpty) {
        continue;
      }
      for (final point in stopPoints) {
        final current = AppLatLng(lat: point.lat, lng: point.lon);
        if (_isDifferentFromLast(path, current)) {
          path.add(current);
        }
      }
    }
    return path;
  }

  _SegmentBearing? _bestSegment(
    List<List<AppLatLng>> candidates,
    AppLatLng position,
  ) {
    _SegmentBearing? best;
    for (final path in candidates) {
      for (var i = 0; i < path.length - 1; i++) {
        final segmentStart = path[i];
        final segmentEnd = path[i + 1];
        final segment = _segmentBearingAndDistance(
          start: segmentStart,
          end: segmentEnd,
          position: position,
        );
        if (segment == null) {
          continue;
        }
        if (best == null || segment.distanceSquared < best.distanceSquared) {
          best = segment;
        }
      }
    }
    return best;
  }

  _SegmentBearing? _segmentBearingAndDistance({
    required AppLatLng start,
    required AppLatLng end,
    required AppLatLng position,
  }) {
    final startPoint = _project(start);
    final endPoint = _project(end, referenceLatRad: startPoint.referenceLatRad);
    final posPoint = _project(position, referenceLatRad: startPoint.referenceLatRad);
    final dx = endPoint.x - startPoint.x;
    final dy = endPoint.y - startPoint.y;
    final lengthSquared = dx * dx + dy * dy;
    if (lengthSquared == 0) {
      return null;
    }

    final t = (((posPoint.x - startPoint.x) * dx) + ((posPoint.y - startPoint.y) * dy)) /
        lengthSquared;
    final clampedT = t.clamp(0.0, 1.0);
    final projectedX = startPoint.x + (dx * clampedT);
    final projectedY = startPoint.y + (dy * clampedT);
    final distanceDx = posPoint.x - projectedX;
    final distanceDy = posPoint.y - projectedY;
    final bearing = _bearingDegrees(start, end);
    return _SegmentBearing(
      bearing: bearing,
      distanceSquared: distanceDx * distanceDx + distanceDy * distanceDy,
    );
  }

  _ProjectedPoint _project(AppLatLng point, {double? referenceLatRad}) {
    final latRad = (point.lat * math.pi) / 180.0;
    final reference = referenceLatRad ?? latRad;
    final x = point.lng * math.cos(reference) * _metersPerDegree;
    final y = point.lat * _metersPerDegree;
    return _ProjectedPoint(
      x: x,
      y: y,
      referenceLatRad: reference,
    );
  }

  int _bearingDegrees(AppLatLng start, AppLatLng end) {
    final startLat = start.lat * math.pi / 180.0;
    final endLat = end.lat * math.pi / 180.0;
    final deltaLng = (end.lng - start.lng) * math.pi / 180.0;
    final y = math.sin(deltaLng) * math.cos(endLat);
    final x = (math.cos(startLat) * math.sin(endLat)) -
        (math.sin(startLat) * math.cos(endLat) * math.cos(deltaLng));
    final bearing = (math.atan2(y, x) * 180.0 / math.pi + 360.0) % 360.0;
    return bearing.round() % 360;
  }

  bool _isKnownStatus(int status) {
    return status == 1 || status == 2;
  }

  bool _isDifferentFromLast(List<AppLatLng> path, AppLatLng next) {
    if (path.isEmpty) {
      return true;
    }
    final last = path.last;
    return (last.lat - next.lat).abs() > _epsilon ||
        (last.lng - next.lng).abs() > _epsilon;
  }

  static const double _metersPerDegree = 111320.0;
  static const double _epsilon = 0.0000001;
}

class _SegmentBearing {
  const _SegmentBearing({
    required this.bearing,
    required this.distanceSquared,
  });

  final int bearing;
  final double distanceSquared;
}

class _ProjectedPoint {
  const _ProjectedPoint({
    required this.x,
    required this.y,
    required this.referenceLatRad,
  });

  final double x;
  final double y;
  final double referenceLatRad;
}
