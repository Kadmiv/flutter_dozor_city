import 'dart:convert';

class GpsPosition {
  const GpsPosition({
    required this.vehicleId,
    required this.routeId,
    required this.timestampMs,
    required this.lat,
    required this.lon,
    required this.speed,
    required this.azimuth,
    required this.govNumber,
    this.rawJson,
  });

  final String vehicleId;
  final String routeId;
  final int timestampMs;
  final double lat;
  final double lon;
  final double speed;
  final int azimuth;
  final String govNumber;
  final Map<String, Object?>? rawJson;

  Map<String, Object?> toJson() => {
    'vehicleId': vehicleId,
    'routeId': routeId,
    'timestampMs': timestampMs,
    'lat': lat,
    'lon': lon,
  };

  static GpsPosition fromJson(Map<String, Object?> json) {
    return GpsPosition(
      vehicleId: _string(json['vehicleId']),
      routeId: _string(json['routeId']),
      timestampMs: _int(json['timestampMs'] ?? json['timestamp']),
      lat: _double(json['lat']),
      lon: _double(json['lon']),
      speed: _double(json['speed']),
      azimuth: _int(json['azimuth']),
      govNumber: _string(json['govNumber']),
      rawJson: _map(json['raw']),
    );
  }
}

class RouteRecord {
  const RouteRecord({
    required this.id,
    required this.shortName,
    required this.title,
    required this.transportType,
    required this.sortOrder,
    required this.isCircle,
  });

  final String id;
  final String shortName;
  final String title;
  final int transportType;
  final int sortOrder;
  final bool isCircle;
}

class StopRecord {
  const StopRecord({
    required this.id,
    required this.name,
    required this.lat,
    required this.lon,
    required this.number,
  });

  final String id;
  final String name;
  final double lat;
  final double lon;
  final int number;
}

class RouteStopRecord {
  const RouteStopRecord({
    required this.routeId,
    required this.stopId,
    required this.stopOrder,
    required this.status,
    required this.times,
  });

  final String routeId;
  final String stopId;
  final int stopOrder;
  final int status;
  final List<String> times;
}

class RoutePolylineRecord {
  const RoutePolylineRecord({
    required this.routeId,
    required this.segmentIndex,
    required this.points,
  });

  final String routeId;
  final int segmentIndex;
  final List<Map<String, Object?>> points;

  String get pointsJson => jsonEncode(points);
}

class RouteTrackStop {
  const RouteTrackStop({
    required this.stopId,
    required this.name,
    required this.lat,
    required this.lon,
    required this.number,
    required this.stopOrder,
    required this.status,
    required this.times,
  });

  final String stopId;
  final String name;
  final double lat;
  final double lon;
  final int number;
  final int stopOrder;
  final int status;
  final List<String> times;
}

class RouteTrackData {
  const RouteTrackData({
    required this.route,
    required this.stops,
    required this.polylineSegments,
  });

  final RouteRecord route;
  final List<RouteTrackStop> stops;
  final List<List<Map<String, Object?>>> polylineSegments;
}

class SegmentEventRecord {
  const SegmentEventRecord({
    required this.vehicleId,
    required this.segmentId,
    required this.startedAtMs,
    required this.finishedAtMs,
    required this.durationSec,
  });

  final String vehicleId;
  final String segmentId;
  final int startedAtMs;
  final int finishedAtMs;
  final int durationSec;
}

class AggregatedSegmentStatRecord {
  const AggregatedSegmentStatRecord({
    required this.segmentId,
    required this.dayType,
    required this.bucketStartMin,
    required this.bucketEndMin,
    required this.sampleCount,
    required this.averageDurationSec,
  });

  final String segmentId;
  final String dayType;
  final int bucketStartMin;
  final int bucketEndMin;
  final int sampleCount;
  final double averageDurationSec;
}

class BatumiSnapshot {
  const BatumiSnapshot({
    required this.routes,
    required this.stops,
    required this.routeStops,
    required this.routePolylines,
  });

  final List<RouteRecord> routes;
  final List<StopRecord> stops;
  final List<RouteStopRecord> routeStops;
  final List<RoutePolylineRecord> routePolylines;
}

String _string(Object? raw) => raw == null ? '' : '$raw';

int _int(Object? raw) {
  if (raw is num) {
    return raw.toInt();
  }
  return int.tryParse(_string(raw)) ?? 0;
}

double _double(Object? raw) {
  if (raw is num) {
    return raw.toDouble();
  }
  return double.tryParse(_string(raw)) ?? 0.0;
}

Map<String, Object?>? _map(Object? raw) {
  if (raw is Map<String, Object?>) {
    return raw;
  }
  if (raw is Map) {
    return raw.map((key, value) => MapEntry('$key', value as Object?));
  }
  return null;
}
