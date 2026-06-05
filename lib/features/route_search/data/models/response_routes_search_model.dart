import 'package:flutter_dozor_city/features/route_search/data/models/json_route_result_model.dart';

class RouteSearchResponseDto {
  const RouteSearchResponseDto({required this.results});

  final List<RouteResultSearchDto> results;

  factory RouteSearchResponseDto.fromJson(Map<String, dynamic> json) {
    final raw = (json['data'] as List?) ?? const [];
    return RouteSearchResponseDto(
      results: raw
          .whereType<Map>()
          .map((item) => RouteResultSearchDto.fromJson(item.cast<String, dynamic>()))
          .toList(growable: false),
    );
  }
}

typedef ResponseRoutesSearchModel = RouteSearchResponseDto;
