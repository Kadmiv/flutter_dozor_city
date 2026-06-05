import 'package:flutter_dozor_city/features/city_data/data/models/device_dto.dart';

class RouteDevicesDto {
  const RouteDevicesDto({
    required this.routeId,
    required this.devices,
  });

  final int routeId;
  final List<VehicleDto> devices;

  factory RouteDevicesDto.fromJson(Map<String, dynamic> json) {
    final rawDevices = (json['dvs'] as List?) ?? (json['devices'] as List?) ?? (json['data'] as List?) ?? const [];
    return RouteDevicesDto(
      routeId: (json['rId'] as num? ?? json['routeId'] as num? ?? json['id'] as num? ?? 0).toInt(),
      devices: rawDevices
          .whereType<Map>()
          .map((item) => VehicleDto.fromJson(item.cast<String, dynamic>()))
          .toList(growable: false),
    );
  }
}

typedef JsonRouteDevicesModel = RouteDevicesDto;
