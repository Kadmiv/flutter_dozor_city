import 'package:flutter_dozor_city/core/data/models/app_lat_lng_model.dart';
import 'package:flutter_dozor_city/core/domain/entities/route_zone.dart';

class JsonRouteZoneModel {
  const JsonRouteZoneModel({
    required this.id,
    required this.names,
    required this.center,
    required this.point,
  });

  final int id;
  final List<String> names;
  final AppLatLngModel? center;
  final AppLatLngModel? point;

  factory JsonRouteZoneModel.fromJson(Map<String, dynamic> json) {
    final rawNames = (json['nm'] as List?) ?? (json['name'] as List?) ?? const [];
    return JsonRouteZoneModel(
      id: (json['id'] as num).toInt(),
      names: rawNames.whereType<String>().toList(growable: false),
      center: json['ctr'] is Map<String, dynamic>
          ? AppLatLngModel.fromJson(json['ctr'] as Map<String, dynamic>)
          : null,
      point: json['pt'] is Map<String, dynamic>
          ? AppLatLngModel.fromJson(json['pt'] as Map<String, dynamic>)
          : null,
    );
  }

  RouteZone toEntity({required String routeId}) {
    return RouteZone(
      id: '$id',
      routeId: routeId,
      name: names.length > 1 ? names[1] : names.firstOrNull ?? 'Zone $id',
    );
  }
}
