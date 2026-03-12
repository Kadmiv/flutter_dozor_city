import 'package:flutter_dozor_city/core/data/models/json_route_devices_model.dart';

class ResponseT2DataModel {
  const ResponseT2DataModel({required this.routes});

  final List<JsonRouteDevicesModel> routes;

  factory ResponseT2DataModel.fromJson(Map<String, dynamic> json) {
    final raw = (json['data'] as List?) ?? const [];
    return ResponseT2DataModel(
      routes: raw
          .whereType<Map>()
          .map((item) => JsonRouteDevicesModel.fromJson(item.cast<String, dynamic>()))
          .toList(growable: false),
    );
  }
}
