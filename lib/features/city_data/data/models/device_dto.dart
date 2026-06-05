import 'package:flutter_dozor_city/core/data/models/app_lat_lng_model.dart';

class VehicleDto {
  const VehicleDto({
    required this.id,
    required this.location,
    required this.azimuth,
    required this.speed,
    required this.govNumber,
  });

  final int id;
  final AppLatLngDto location;
  final int azimuth;
  final int speed;
  final String govNumber;

  factory VehicleDto.fromJson(Map<String, Object?> json) {
    return VehicleDto(
      id: _int(json['id']),
      location: AppLatLngDto.fromJson(
        _objectMap(json['loc']) ?? _objectMap(json['location']) ?? const {},
      ),
      azimuth: _int(json['azi'] ?? json['azimuth']),
      speed: _int(json['spd'] ?? json['speed']),
      govNumber: _string(json['gNb'] ?? json['govNumber']),
    );
  }
}

typedef JsonDeviceModel = VehicleDto;

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

String _string(Object? raw) => raw == null ? '' : '$raw';
