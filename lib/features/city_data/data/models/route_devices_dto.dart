import 'package:flutter_dozor_city/features/city_data/data/models/device_dto.dart';

class RouteDevicesDto {
  const RouteDevicesDto({
    required this.routeId,
    required this.devices,
  });

  final int routeId;
  final List<VehicleDto> devices;

  factory RouteDevicesDto.fromJson(Map<String, Object?> json) {
    final rawDevices = _objectList(json['dvs']) ??
        _objectList(json['devices']) ??
        _objectList(json['data']) ??
        const [];
    return RouteDevicesDto(
      routeId: _int(json['rId'] ?? json['routeId'] ?? json['id']),
      devices: rawDevices
          .map((item) => VehicleDto.fromJson(item))
          .toList(growable: false),
    );
  }
}

typedef JsonRouteDevicesModel = RouteDevicesDto;

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

int _int(Object? raw) {
  if (raw is num) {
    return raw.toInt();
  }
  return int.tryParse('$raw') ?? 0;
}
