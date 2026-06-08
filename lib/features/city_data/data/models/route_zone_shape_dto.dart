import 'package:flutter_dozor_city/core/data/models/app_lat_lng_model.dart';
import 'package:flutter_dozor_city/core/domain/entities/app_lat_lng.dart';
import 'package:flutter_dozor_city/core/domain/entities/route_zone.dart';

class RouteZoneShapeDto {
  const RouteZoneShapeDto({
    required this.id,
    required this.names,
    required this.center,
    required this.point,
  });

  final int id;
  final List<String> names;
  final AppLatLngDto? center;
  final AppLatLngDto? point;

  factory RouteZoneShapeDto.fromJson(Map<String, Object?> json) {
    final rawNames =
        _stringList(json['nm']) ?? _stringList(json['name']) ?? const [];
    return RouteZoneShapeDto(
      id: _int(json['id']),
      names: rawNames,
      center: _objectMap(json['ctr']) == null
          ? null
          : AppLatLngDto.fromJson(_objectMap(json['ctr'])!),
      point: _objectMap(json['pt']) == null
          ? null
          : AppLatLngDto.fromJson(_objectMap(json['pt'])!),
    );
  }

  RouteZone toEntity({required String routeId}) {
    return RouteZone(
      id: '$id',
      routeId: routeId,
      name: names.length > 1 ? names[1] : names.firstOrNull ?? 'Zone $id',
      nameKa: names.length > 1 ? names[0] : names.firstOrNull,
      nameEn: names.length > 1 ? names[1] : names.firstOrNull,
      position: point == null
          ? center == null
              ? null
              : AppLatLng(lat: center!.lat, lng: center!.lng)
          : AppLatLng(lat: point!.lat, lng: point!.lng),
    );
  }
}

typedef JsonRouteZoneModel = RouteZoneShapeDto;

List<String>? _stringList(Object? raw) {
  if (raw is List) {
    return raw
        .map((item) => '$item')
        .where((item) => item.isNotEmpty)
        .toList(growable: false);
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
