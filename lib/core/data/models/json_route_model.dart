import 'package:flutter_dozor_city/core/data/models/json_route_line_model.dart';
import 'package:flutter_dozor_city/core/data/models/json_route_zone_model.dart';
import 'package:flutter_dozor_city/core/domain/entities/transport_route.dart';
import 'package:flutter_dozor_city/core/presentation/route_display_color.dart';

class JsonRouteModel {
  const JsonRouteModel({
    required this.id,
    required this.names,
    required this.shortName,
    required this.info,
    required this.transportType,
    required this.lines,
    required this.zones,
    required this.outLineColor,
    required this.price,
  });

  final int id;
  final List<String> names;
  final String shortName;
  final String info;
  final int? transportType;
  final List<JsonRouteLineModel> lines;
  final List<JsonRouteZoneModel> zones;
  final String outLineColor;
  final double price;

  factory JsonRouteModel.fromJson(Map<String, dynamic> json) {
    final rawNames = (json['nm'] as List?) ?? (json['name'] as List?) ?? const [];
    final rawLines = (json['lns'] as List?) ?? (json['lines'] as List?) ?? const [];
    final rawZones = (json['zns'] as List?) ?? (json['zones'] as List?) ?? const [];
    return JsonRouteModel(
      id: (json['id'] as num).toInt(),
      names: rawNames.whereType<String>().toList(growable: false),
      shortName: json['sNm'] as String? ?? json['shortName'] as String? ?? '',
      info: json['inf'] as String? ?? json['info'] as String? ?? '',
      transportType: (json['transportType'] as num?)?.toInt(),
      lines: rawLines
          .whereType<Map>()
          .map((item) => JsonRouteLineModel.fromJson(item.cast<String, dynamic>()))
          .toList(growable: false),
      zones: rawZones
          .whereType<Map>()
          .map((item) => JsonRouteZoneModel.fromJson(item.cast<String, dynamic>()))
          .toList(growable: false),
      outLineColor: json['oLC'] as String? ?? json['outLineColor'] as String? ?? '',
      price: (json['prc'] as num? ?? json['price'] as num? ?? 0).toDouble(),
    );
  }

  TransportRoute toEntity({required int transportType}) {
    final polylineSegments = lines
        .map(
          (line) => line.points
              .map((point) => point.toEntity())
              .toList(growable: false),
        )
        .where((segment) => segment.length > 1)
        .toList(growable: false);
    final routeTitle =
        names.length > 1 ? names[1] : names.firstOrNull ?? 'Route $id';
    final displayColorValue = RouteDisplayColor.fromRouteIdentity(
      shortName: shortName,
      title: routeTitle,
    );
    return TransportRoute(
      id: '$id',
      shortName: shortName,
      title: routeTitle,
      transportType: transportType,
      polylineSegments: polylineSegments,
      lineColorValue: displayColorValue,
    );
  }
}
