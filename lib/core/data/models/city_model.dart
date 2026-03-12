import 'package:flutter_dozor_city/core/domain/entities/city.dart';

class CityModel {
  const CityModel({
    required this.id,
    required this.name,
    required this.region,
    required this.centerLat,
    required this.centerLng,
    required this.zoom,
  });

  final String id;
  final String name;
  final String region;
  final double centerLat;
  final double centerLng;
  final double zoom;

  factory CityModel.fromJson(Map<String, dynamic> json) {
    final latLng = json['latLng'] is Map
        ? (json['latLng'] as Map).cast<String, dynamic>()
        : null;
    final name = (json['name'] as String?) ??
        (json['name0'] as String?) ??
        (json['name1'] as String?) ??
        '';
    final centerLat = (json['centerLat'] as num?) ??
        (json['lat'] as num?) ??
        (latLng?['lat'] as num?) ??
        0;
    final centerLng = (json['centerLng'] as num?) ??
        (json['lng'] as num?) ??
        (latLng?['lng'] as num?) ??
        0;
    return CityModel(
      id: (json['id'] as String?) ?? (json['cityId'] as String?) ?? '',
      name: name,
      region: json['region'] as String? ?? '',
      centerLat: centerLat.toDouble(),
      centerLng: centerLng.toDouble(),
      zoom: (json['zoom'] as num? ?? 12).toDouble(),
    );
  }

  City toEntity() {
    return City(
      id: id,
      name: name,
      region: region,
      centerLat: centerLat,
      centerLng: centerLng,
      zoom: zoom,
    );
  }
}
