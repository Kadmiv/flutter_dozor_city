typedef JsonMap = Map<String, Object?>;

class BatumiDbDataDto {
  const BatumiDbDataDto({
    required this.busStops,
    required this.routeStatusInfo,
    required this.routesNames,
    required this.routeCoordinatesGrouped,
  });

  final Map<String, BatumiBusStopDto> busStops;
  final Map<String, BatumiRouteStatusInfoDto> routeStatusInfo;
  final Map<String, BatumiRouteNameDto> routesNames;
  final Map<String, BatumiRouteCoordinatesDto> routeCoordinatesGrouped;

  factory BatumiDbDataDto.fromApiResponse(Object? raw) {
    return BatumiDbDataDto.fromJson(_topLevelObjectMap(raw));
  }

  factory BatumiDbDataDto.fromJson(JsonMap json) {
    final data = _objectMap(json['data']) ?? json;
    return BatumiDbDataDto(
      busStops: _readObjectMap(
        data['busStops'],
        (value) => BatumiBusStopDto.fromJson(_objectMap(value) ?? const {}),
      ),
      routeStatusInfo: _readObjectMap(
        data['routeStatusInfo'],
        (value) => BatumiRouteStatusInfoDto.fromJson(_objectMap(value) ?? const {}),
      ),
      routesNames: _readObjectMap(
        data['routesNames'],
        (value) => BatumiRouteNameDto.fromJson(_objectMap(value) ?? const {}),
      ),
      routeCoordinatesGrouped: _readObjectMap(
        data['routeCoordinatesGrouped'],
        (value) => BatumiRouteCoordinatesDto.fromJson(_objectMap(value) ?? const {}),
      ),
    );
  }

  static Map<String, T> _readObjectMap<T>(
    Object? raw,
    T Function(Object? value) parseValue,
  ) {
    final map = _objectMap(raw);
    if (map == null) {
      return const {};
    }
    final result = <String, T>{};
    for (final entry in map.entries) {
      result[entry.key] = parseValue(entry.value);
    }
    return result;
  }
}

class BatumiBusStopDto {
  const BatumiBusStopDto({
    required this.id,
    required this.nameGeoGps,
    required this.number,
    required this.nameKa,
    required this.nameEn,
    required this.lat,
    required this.lon,
    required this.routeTRouteIdGeoGps,
    required this.routes,
  });

  final String id;
  final String nameGeoGps;
  final int number;
  final String nameKa;
  final String nameEn;
  final double lat;
  final double lon;
  final String? routeTRouteIdGeoGps;
  final Map<String, BatumiBusStopRouteDto> routes;

  factory BatumiBusStopDto.fromJson(JsonMap json) {
    return BatumiBusStopDto(
      id: _string(json['BusStopIdGeoGps']),
      nameGeoGps: _string(json['BusStopNameGeoGps']),
      number: _int(json['BusStopNumber']),
      nameKa: _string(json['BusStopNameKA']),
      nameEn: _string(json['BusStopNameEN']),
      lat: _double(json['BusStopLatitude']),
      lon: _double(json['BusStopLongitude']),
      routeTRouteIdGeoGps: _stringOrNull(json['RouteT_RouteIdGeoGps']),
      routes: BatumiDbDataDto._readObjectMap(
        json['routes'],
        (value) => BatumiBusStopRouteDto.fromJson(_objectMap(value) ?? const {}),
      ),
    );
  }
}

class BatumiBusStopRouteDto {
  const BatumiBusStopRouteDto({
    required this.status,
    required this.order,
    required this.times,
  });

  final int status;
  final int order;
  final List<String> times;

  factory BatumiBusStopRouteDto.fromJson(JsonMap json) {
    return BatumiBusStopRouteDto(
      status: _int(json['Status']),
      order: _int(json['Order']),
      times: _stringList(json['times']),
    );
  }
}

class BatumiRouteNameDto {
  const BatumiRouteNameDto({
    required this.routeId,
    required this.shortName,
    required this.titleKa,
    required this.titleEn,
    required this.isCircle,
    required this.sortOrder,
  });

  final String routeId;
  final String shortName;
  final String titleKa;
  final String titleEn;
  final bool isCircle;
  final int sortOrder;

  factory BatumiRouteNameDto.fromJson(JsonMap json) {
    return BatumiRouteNameDto(
      routeId: _string(json['RouteIdGeoGps']),
      shortName: _string(json['RouteNameEN']),
      titleKa: _string(json['RouteNameKA']),
      titleEn: _string(json['RouteNameEN']),
      isCircle: _bool(json['RouteIsCircle']),
      sortOrder: _int(json['RouteSortOrder']),
    );
  }
}

class BatumiRouteStatusInfoDto {
  const BatumiRouteStatusInfoDto({required this.directions});

  final Map<String, BatumiRouteStatusDirectionDto> directions;

  factory BatumiRouteStatusInfoDto.fromJson(JsonMap json) {
    return BatumiRouteStatusInfoDto(
      directions: BatumiDbDataDto._readObjectMap(
        json,
        (value) => BatumiRouteStatusDirectionDto.fromJson(_objectMap(value) ?? const {}),
      ),
    );
  }
}

class BatumiRouteStatusDirectionDto {
  const BatumiRouteStatusDirectionDto({
    required this.lowestId,
    required this.highestId,
  });

  final String lowestId;
  final String highestId;

  factory BatumiRouteStatusDirectionDto.fromJson(JsonMap json) {
    return BatumiRouteStatusDirectionDto(
      lowestId: _string(json['lowestId']),
      highestId: _string(json['highestId']),
    );
  }
}

class BatumiRouteCoordinatesDto {
  const BatumiRouteCoordinatesDto({required this.points});

  final Map<int, BatumiCoordinateDto> points;

  List<BatumiCoordinateDto> get orderedPoints {
    final entries = points.entries.toList(growable: false)
      ..sort((a, b) => a.key.compareTo(b.key));
    return entries.map((entry) => entry.value).toList(growable: false);
  }

  factory BatumiRouteCoordinatesDto.fromJson(JsonMap json) {
    final points = <int, BatumiCoordinateDto>{};
    for (final entry in json.entries) {
      final key = int.tryParse(entry.key) ?? points.length;
      final value = entry.value;
      final point = _parsePoint(value);
      if (point != null) {
        points[key] = point;
      }
    }
    return BatumiRouteCoordinatesDto(points: points);
  }

  static BatumiCoordinateDto? _parsePoint(Object? raw) {
    final map = _objectMap(raw);
    if (map != null) {
      return BatumiCoordinateDto(
        lat: _double(map['lat']),
        lon: _double(map['lon']),
      );
    }
    if (raw is List && raw.length >= 2) {
      return BatumiCoordinateDto(
        lat: _double(raw[0]),
        lon: _double(raw[1]),
      );
    }
    return null;
  }
}

class BatumiCoordinateDto {
  const BatumiCoordinateDto({
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
      result['${entry.key}'] = entry.value is Map || entry.value is List
          ? entry.value
          : entry.value as Object?;
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

String _string(Object? raw) => raw == null ? '' : '$raw';

String? _stringOrNull(Object? raw) {
  final value = _string(raw).trim();
  return value.isEmpty ? null : value;
}

int _int(Object? raw) {
  if (raw is num) {
    return raw.toInt();
  }
  return int.tryParse(_string(raw)) ?? 0;
}

double _double(Object? raw) {
  if (raw is num) {
    return raw.toDouble();
  }
  return double.tryParse(_string(raw)) ?? 0;
}

bool _bool(Object? raw) {
  if (raw is bool) {
    return raw;
  }
  final value = _string(raw).toLowerCase();
  return value == 'true' || value == '1';
}

List<String> _stringList(Object? raw) {
  if (raw is List) {
    return raw.map(_string).where((item) => item.isNotEmpty).toList(growable: false);
  }
  return const [];
}
