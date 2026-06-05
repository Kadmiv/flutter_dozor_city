import 'package:flutter_dozor_city/features/city_data/data/models/route_dto.dart';

class CityRoutesResponseDto {
  const CityRoutesResponseDto({required this.routes});

  final List<RouteDto> routes;

  factory CityRoutesResponseDto.fromJson(Map<String, Object?> json) {
    final raw = _objectList(json['data']) ?? const [];
    return CityRoutesResponseDto(
      routes: raw
          .map((item) => RouteDto.fromJson(item))
          .toList(growable: false),
    );
  }
}

typedef ResponseT1DataModel = CityRoutesResponseDto;

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
