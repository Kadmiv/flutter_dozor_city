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

  factory VehicleDto.fromJson(Map<String, dynamic> json) {
    return VehicleDto(
      id: (json['id'] as num).toInt(),
      location: AppLatLngDto.fromJson(
        (json['loc'] as Map?)?.cast<String, dynamic>() ??
            (json['location'] as Map).cast<String, dynamic>(),
      ),
      azimuth: (json['azi'] as num? ?? json['azimuth'] as num? ?? 0).toInt(),
      speed: (json['spd'] as num? ?? json['speed'] as num? ?? 0).toInt(),
      govNumber: json['gNb'] as String? ?? json['govNumber'] as String? ?? '',
    );
  }
}

typedef JsonDeviceModel = VehicleDto;
