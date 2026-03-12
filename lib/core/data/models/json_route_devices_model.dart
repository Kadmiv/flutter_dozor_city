import 'package:flutter_dozor_city/core/data/models/json_device_model.dart';

class JsonRouteDevicesModel {
  const JsonRouteDevicesModel({
    required this.routeId,
    required this.devices,
  });

  final int routeId;
  final List<JsonDeviceModel> devices;

  factory JsonRouteDevicesModel.fromJson(Map<String, dynamic> json) {
    final rawDevices = (json['dvs'] as List?) ?? (json['devices'] as List?) ?? (json['data'] as List?) ?? const [];
    return JsonRouteDevicesModel(
      routeId: (json['rId'] as num? ?? json['routeId'] as num? ?? json['id'] as num? ?? 0).toInt(),
      devices: rawDevices
          .whereType<Map>()
          .map((item) => JsonDeviceModel.fromJson(item.cast<String, dynamic>()))
          .toList(growable: false),
    );
  }
}
