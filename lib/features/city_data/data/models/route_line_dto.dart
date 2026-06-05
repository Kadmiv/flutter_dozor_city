import 'package:flutter_dozor_city/core/data/models/app_lat_lng_model.dart';

class RouteLineDto {
  const RouteLineDto({
    required this.points,
  });

  final List<AppLatLngDto> points;

  factory RouteLineDto.fromJson(Map<String, dynamic> json) {
    final rawPoints = (json['pts'] as List?) ?? (json['points'] as List?) ?? const [];
    return RouteLineDto(
      points: rawPoints
          .whereType<Map>()
          .map((item) => AppLatLngDto.fromJson(item.cast<String, dynamic>()))
          .toList(growable: false),
    );
  }
}

typedef JsonRouteLineModel = RouteLineDto;
