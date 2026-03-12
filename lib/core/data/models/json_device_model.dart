import 'package:flutter_dozor_city/core/data/models/app_lat_lng_model.dart';

class JsonDeviceModel {
  const JsonDeviceModel({
    required this.id,
    required this.location,
    required this.azimuth,
    required this.speed,
    required this.govNumber,
  });

  final int id;
  final AppLatLngModel location;
  final int azimuth;
  final int speed;
  final String govNumber;

  factory JsonDeviceModel.fromJson(Map<String, dynamic> json) {
    return JsonDeviceModel(
      id: (json['id'] as num).toInt(),
      location: AppLatLngModel.fromJson(
        (json['loc'] as Map?)?.cast<String, dynamic>() ??
            (json['location'] as Map).cast<String, dynamic>(),
      ),
      azimuth: (json['azi'] as num? ?? json['azimuth'] as num? ?? 0).toInt(),
      speed: (json['spd'] as num? ?? json['speed'] as num? ?? 0).toInt(),
      govNumber: json['gNb'] as String? ?? json['govNumber'] as String? ?? '',
    );
  }
}
