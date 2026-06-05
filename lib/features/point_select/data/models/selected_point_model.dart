import 'package:flutter_dozor_city/core/domain/entities/selected_point.dart';

class SelectedPointDto {
  const SelectedPointDto({
    required this.label,
    required this.lat,
    required this.lng,
    required this.source,
    this.zoneId,
  });

  final String label;
  final double lat;
  final double lng;
  final SelectedPointSource source;
  final int? zoneId;

  factory SelectedPointDto.fromJson(Map<String, dynamic> json) {
    final sourceRaw = json['source'] as String? ?? 'address';
    final source = SelectedPointSource.values.firstWhere(
      (value) => value.name == sourceRaw,
      orElse: () => SelectedPointSource.address,
    );
    return SelectedPointDto(
      label: json['label'] as String? ?? json['name'] as String? ?? '',
      lat: (json['lat'] as num).toDouble(),
      lng: (json['lng'] as num).toDouble(),
      source: source,
      zoneId: (json['zoneId'] as num?)?.toInt(),
    );
  }

  SelectedPoint toEntity() {
    return SelectedPoint(
      label: label,
      lat: lat,
      lng: lng,
      source: source,
      zoneId: zoneId,
    );
  }
}

typedef SelectedPointModel = SelectedPointDto;
