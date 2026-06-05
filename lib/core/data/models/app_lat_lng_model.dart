import 'package:flutter_dozor_city/core/domain/entities/app_lat_lng.dart';

class AppLatLngDto {
  const AppLatLngDto({
    required this.lat,
    required this.lng,
  });

  final double lat;
  final double lng;

  factory AppLatLngDto.fromJson(Map<String, dynamic> json) {
    return AppLatLngDto(
      lat: (json['lat'] as num).toDouble(),
      lng: (json['lng'] as num).toDouble(),
    );
  }

  AppLatLng toEntity() {
    return AppLatLng(lat: lat, lng: lng);
  }
}

typedef AppLatLngModel = AppLatLngDto;
