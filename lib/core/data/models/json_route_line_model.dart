import 'package:flutter_dozor_city/core/data/models/app_lat_lng_model.dart';

class JsonRouteLineModel {
  const JsonRouteLineModel({
    required this.points,
  });

  final List<AppLatLngModel> points;

  factory JsonRouteLineModel.fromJson(Map<String, dynamic> json) {
    final rawPoints = (json['pts'] as List?) ?? (json['points'] as List?) ?? const [];
    return JsonRouteLineModel(
      points: rawPoints
          .whereType<Map>()
          .map((item) => AppLatLngModel.fromJson(item.cast<String, dynamic>()))
          .toList(growable: false),
    );
  }
}
