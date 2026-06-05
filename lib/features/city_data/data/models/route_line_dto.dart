import 'package:flutter_dozor_city/core/data/models/app_lat_lng_model.dart';

class RouteLineDto {
  const RouteLineDto({
    required this.points,
  });

  final List<AppLatLngDto> points;

  factory RouteLineDto.fromJson(Map<String, Object?> json) {
    final rawPoints = _objectList(json['pts']) ?? _objectList(json['points']) ?? const [];
    return RouteLineDto(
      points: rawPoints
          .map((item) => AppLatLngDto.fromJson(item))
          .toList(growable: false),
    );
  }
}

typedef JsonRouteLineModel = RouteLineDto;

List<Map<String, Object?>>? _objectList(Object? raw) {
  if (raw is List) {
    final result = <Map<String, Object?>>[];
    for (final item in raw) {
      final map = _objectMap(item);
      if (map != null) {
        result.add(map);
      }
    }
    return result;
  }
  return null;
}

Map<String, Object?>? _objectMap(Object? raw) {
  if (raw is Map<String, Object?>) {
    return raw;
  }
  if (raw is Map) {
    final result = <String, Object?>{};
    for (final entry in raw.entries) {
      result['${entry.key}'] = entry.value;
    }
    return result;
  }
  return null;
}
