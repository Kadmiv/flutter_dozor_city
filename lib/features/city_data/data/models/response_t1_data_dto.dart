import 'package:flutter_dozor_city/features/city_data/data/models/route_dto.dart';

class CityRoutesResponseDto {
  const CityRoutesResponseDto({required this.routes});

  final List<RouteDto> routes;

  factory CityRoutesResponseDto.fromJson(Map<String, dynamic> json) {
    final raw = (json['data'] as List?) ?? const [];
    return CityRoutesResponseDto(
      routes: raw
          .whereType<Map>()
          .map((item) => RouteDto.fromJson(item.cast<String, dynamic>()))
          .toList(growable: false),
    );
  }
}

typedef ResponseT1DataModel = CityRoutesResponseDto;
