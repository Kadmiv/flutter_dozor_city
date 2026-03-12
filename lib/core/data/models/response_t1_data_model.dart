import 'package:flutter_dozor_city/core/data/models/json_route_model.dart';

class ResponseT1DataModel {
  const ResponseT1DataModel({required this.routes});

  final List<JsonRouteModel> routes;

  factory ResponseT1DataModel.fromJson(Map<String, dynamic> json) {
    final raw = (json['data'] as List?) ?? const [];
    return ResponseT1DataModel(
      routes: raw
          .whereType<Map>()
          .map((item) => JsonRouteModel.fromJson(item.cast<String, dynamic>()))
          .toList(growable: false),
    );
  }
}
