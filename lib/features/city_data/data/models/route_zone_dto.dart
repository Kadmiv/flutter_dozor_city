import 'package:flutter_dozor_city/core/domain/entities/app_lat_lng.dart';
import 'package:flutter_dozor_city/core/domain/entities/route_zone.dart';

class RouteZoneDto {
  const RouteZoneDto({
    required this.id,
    required this.routeId,
    required this.name,
  });

  final String id;
  final String routeId;
  final String name;

  factory RouteZoneDto.fromJson(Map<String, Object?> json) {
    return RouteZoneDto(
      id: _string(json['id']),
      routeId: _string(json['routeId']),
      name: _string(json['name']).isNotEmpty
          ? _string(json['name'])
          : _string(json['nm']),
    );
  }

  RouteZone toEntity({AppLatLng? position}) {
    return RouteZone(
      id: id,
      routeId: routeId,
      name: name,
      nameEn: name,
      nameKa: name,
      position: position,
    );
  }
}

typedef RouteZoneModel = RouteZoneDto;

String _string(Object? raw) => raw == null ? '' : '$raw';
