import 'package:flutter_dozor_city/features/city_data/data/models/route_devices_dto.dart';

class CityVehiclesResponseDto {
  const CityVehiclesResponseDto({required this.routes});

  final List<RouteDevicesDto> routes;

  factory CityVehiclesResponseDto.fromJson(Map<String, dynamic> json) {
    final raw = (json['data'] as List?) ?? const [];
    return CityVehiclesResponseDto(
      routes: raw
          .whereType<Map>()
          .map((item) => RouteDevicesDto.fromJson(item.cast<String, dynamic>()))
          .toList(growable: false),
    );
  }
}

typedef ResponseT2DataModel = CityVehiclesResponseDto;
