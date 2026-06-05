typedef JsonMap = Map<String, Object?>;

class BatumiPointsBetweenStationsDto {
  const BatumiPointsBetweenStationsDto({required this.data});

  final Map<String, Map<String, List<BatumiPointBetweenStationsDto>>> data;

  factory BatumiPointsBetweenStationsDto.fromApiResponse(Object? raw) {
    return BatumiPointsBetweenStationsDto.fromJson(_topLevelObjectMap(raw));
  }

  factory BatumiPointsBetweenStationsDto.fromJson(JsonMap json) {
    final data = _objectMap(json['data']) ?? json;
    final routes = <String, Map<String, List<BatumiPointBetweenStationsDto>>>{};
    for (final routeEntry in data.entries) {
      final stopsMap = _objectMap(routeEntry.value);
      if (stopsMap == null) {
        continue;
      }
      final stops = <String, List<BatumiPointBetweenStationsDto>>{};
      for (final stopEntry in stopsMap.entries) {
        final rawPoints = stopEntry.value;
        final points = <BatumiPointBetweenStationsDto>[];
        if (rawPoints is List) {
          for (final rawPoint in rawPoints) {
            final point = _parsePoint(rawPoint);
            if (point != null) {
              points.add(point);
            }
          }
        }
        stops[stopEntry.key] = points;
      }
      routes[routeEntry.key] = stops;
    }
    return BatumiPointsBetweenStationsDto(data: routes);
  }

  static BatumiPointBetweenStationsDto? _parsePoint(Object? raw) {
    if (raw is List && raw.length >= 2) {
      return BatumiPointBetweenStationsDto(
        lat: _double(raw[0]),
        lon: _double(raw[1]),
      );
    }
    final map = _objectMap(raw);
    if (map != null) {
      return BatumiPointBetweenStationsDto(
        lat: _double(map['lat']),
        lon: _double(map['lon']),
      );
    }
    return null;
  }
}

class BatumiPointBetweenStationsDto {
  const BatumiPointBetweenStationsDto({
    required this.lat,
    required this.lon,
  });

  final double lat;
  final double lon;
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

double _double(Object? raw) {
  if (raw is num) {
    return raw.toDouble();
  }
  return double.tryParse('$raw') ?? 0;
}
