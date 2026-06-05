import 'package:flutter_dozor_city/core/domain/entities/city.dart';

class CityDto {
  const CityDto({
    required this.id,
    required this.name,
    required this.region,
    required this.centerLat,
    required this.centerLng,
    required this.zoom,
  });

  final String id;
  final String name;
  final String region;
  final double centerLat;
  final double centerLng;
  final double zoom;

  factory CityDto.fromJson(Map<String, Object?> json) {
    final latLng = _objectMap(json['latLng']);
    final name = _string(json['name']).isNotEmpty
        ? _string(json['name'])
        : _string(json['name0']).isNotEmpty
            ? _string(json['name0'])
            : _string(json['name1']);
    final centerLat = _double(json['centerLat'] ?? json['lat'] ?? latLng?['lat']);
    final centerLng = _double(json['centerLng'] ?? json['lng'] ?? latLng?['lng']);
    return CityDto(
      id: _string(json['id']).isNotEmpty ? _string(json['id']) : _string(json['cityId']),
      name: name,
      region: _string(json['region']),
      centerLat: centerLat,
      centerLng: centerLng,
      zoom: _double(json['zoom'] ?? 12),
    );
  }

  City toEntity() {
    return City(
      id: id,
      name: name,
      region: region,
      centerLat: centerLat,
      centerLng: centerLng,
      zoom: zoom,
    );
  }
}

typedef CityModel = CityDto;

Map<String, Object?>? _objectMap(Object? raw) {
  if (raw is Map<String, Object?>) {
    return raw;
  }
  if (raw is Map) {
    final result = <String, Object?>{};
    for (final entry in raw.entries) {
      result['${entry.key}'] = entry.value;
    }
    return result;
  }
  return null;
}

String _string(Object? raw) => raw == null ? '' : '$raw';

double _double(Object? raw) {
  if (raw is num) {
    return raw.toDouble();
  }
  return double.tryParse('$raw') ?? 0;
}
