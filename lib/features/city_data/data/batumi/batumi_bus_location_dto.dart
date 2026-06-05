typedef JsonMap = Map<String, Object?>;

class BatumiBusLocationDto {
  const BatumiBusLocationDto({
    required this.lat,
    required this.lon,
    required this.status,
    required this.name,
  });

  final double lat;
  final double lon;
  final int status;
  final String name;

  factory BatumiBusLocationDto.fromJson(JsonMap json) {
    return BatumiBusLocationDto(
      lat: _double(json['Lat']),
      lon: _double(json['Lon']),
      status: _int(json['Status']),
      name: _string(json['Name']),
    );
  }
}

class BatumiBusLocationsResponseDto {
  const BatumiBusLocationsResponseDto({required this.locations});

  final List<BatumiBusLocationDto> locations;

  factory BatumiBusLocationsResponseDto.fromApiResponse(Object? raw) {
    return BatumiBusLocationsResponseDto.fromJson(_topLevelObjectMap(raw));
  }

  factory BatumiBusLocationsResponseDto.fromJson(JsonMap json) {
    final raw = json['data'];
    final locations = <BatumiBusLocationDto>[];
    if (raw is List) {
      for (final item in raw) {
        final map = _objectMap(item);
        if (map != null) {
          locations.add(BatumiBusLocationDto.fromJson(map));
        }
      }
    }
    return BatumiBusLocationsResponseDto(locations: locations);
  }
}

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

Map<String, Object?> _topLevelObjectMap(Object? raw) {
  final map = _objectMap(raw);
  if (map != null) {
    return map;
  }
  throw FormatException('Expected JSON object');
}

int _int(Object? raw) {
  if (raw is num) {
    return raw.toInt();
  }
  return int.tryParse('$raw') ?? 0;
}

double _double(Object? raw) {
  if (raw is num) {
    return raw.toDouble();
  }
  return double.tryParse('$raw') ?? 0;
}

String _string(Object? raw) => raw == null ? '' : '$raw';
