import 'package:flutter_dozor_city/core/domain/entities/route_zone.dart';

class RouteZoneModel {
  const RouteZoneModel({
    required this.id,
    required this.routeId,
    required this.name,
  });

  final String id;
  final String routeId;
  final String name;

  factory RouteZoneModel.fromJson(Map<String, dynamic> json) {
    return RouteZoneModel(
      id: '${json['id']}',
      routeId: '${json['routeId'] ?? ''}',
      name: json['name'] as String? ?? json['nm'] as String? ?? '',
    );
  }

  RouteZone toEntity() {
    return RouteZone(
      id: id,
      routeId: routeId,
      name: name,
    );
  }
}
