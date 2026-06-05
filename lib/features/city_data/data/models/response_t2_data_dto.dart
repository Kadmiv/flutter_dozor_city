import 'package:flutter_dozor_city/features/city_data/data/models/route_devices_dto.dart';

class CityVehiclesResponseDto {
  const CityVehiclesResponseDto({required this.routes});

  final List<RouteDevicesDto> routes;

  factory CityVehiclesResponseDto.fromJson(Map<String, Object?> json) {
    final raw = _objectList(json['data']) ?? const [];
    return CityVehiclesResponseDto(
      routes: raw
          .map((item) => RouteDevicesDto.fromJson(item))
          .toList(growable: false),
    );
  }
}

typedef ResponseT2DataModel = CityVehiclesResponseDto;

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
