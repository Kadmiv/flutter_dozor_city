import 'package:flutter_dozor_city/core/domain/entities/app_lat_lng.dart';

class AppLatLngDto {
  const AppLatLngDto({
    required this.lat,
    required this.lng,
  });

  final double lat;
  final double lng;

  factory AppLatLngDto.fromJson(Map<String, Object?> json) {
    return AppLatLngDto(
      lat: _double(json['lat']),
      lng: _double(json['lng']),
    );
  }

  AppLatLng toEntity() {
    return AppLatLng(lat: lat, lng: lng);
  }
}

typedef AppLatLngModel = AppLatLngDto;

double _double(Object? raw) {
  if (raw is num) {
    return raw.toDouble();
  }
  return double.tryParse('$raw') ?? 0;
}
