import 'package:flutter_dozor_city/core/data/models/json_route_result_model.dart';

class ResponseRoutesSearchModel {
  const ResponseRoutesSearchModel({required this.results});

  final List<JsonRouteResultModel> results;

  factory ResponseRoutesSearchModel.fromJson(Map<String, dynamic> json) {
    final raw = (json['data'] as List?) ?? const [];
    return ResponseRoutesSearchModel(
      results: raw
          .whereType<Map>()
          .map((item) => JsonRouteResultModel.fromJson(item.cast<String, dynamic>()))
          .toList(growable: false),
    );
  }
}
