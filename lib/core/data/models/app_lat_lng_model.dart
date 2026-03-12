import 'package:flutter_dozor_city/core/domain/entities/app_lat_lng.dart';

class AppLatLngModel {
  const AppLatLngModel({
    required this.lat,
    required this.lng,
  });

  final double lat;
  final double lng;

  factory AppLatLngModel.fromJson(Map<String, dynamic> json) {
    return AppLatLngModel(
      lat: (json['lat'] as num).toDouble(),
      lng: (json['lng'] as num).toDouble(),
    );
  }

  AppLatLng toEntity() {
    return AppLatLng(lat: lat, lng: lng);
  }
}
