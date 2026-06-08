typedef JsonMap = Map<String, Object?>;

class BatumiLiveDataResponseDto {
  const BatumiLiveDataResponseDto({required this.arrivalTimes});

  final List<BatumiStopArrivalDto> arrivalTimes;

  factory BatumiLiveDataResponseDto.fromApiResponse(Object? raw) {
    return BatumiLiveDataResponseDto.fromJson(_topLevelObjectMap(raw));
  }

  factory BatumiLiveDataResponseDto.fromJson(JsonMap json) {
    final data = _objectMap(json['data']) ?? json;
    final rawArrivalTimes = data['arrivalTime'];
    final arrivalTimes = <BatumiStopArrivalDto>[];
    if (rawArrivalTimes is List) {
      for (final item in rawArrivalTimes) {
        final map = _objectMap(item);
        if (map != null) {
          arrivalTimes.add(BatumiStopArrivalDto.fromJson(map));
        }
      }
    }
    return BatumiLiveDataResponseDto(arrivalTimes: arrivalTimes);
  }
}

class BatumiStopArrivalDto {
  const BatumiStopArrivalDto({
    required this.name,
    required this.stopId,
    required this.arrivalTimes,
  });

  final String name;
  final String stopId;
  final List<BatumiRouteBusArrivalDto> arrivalTimes;

  factory BatumiStopArrivalDto.fromJson(JsonMap json) {
    return BatumiStopArrivalDto(
      name: _string(json['name']),
      stopId: _string(json['stop_id']),
      arrivalTimes: _parseArrivalTimes(json['arrival_times']),
    );
  }
}

class BatumiRouteBusArrivalDto {
  const BatumiRouteBusArrivalDto({
    required this.busId,
    required this.busName,
    required this.minute,
  });

  final String busId;
  final String busName;
  final int minute;

  factory BatumiRouteBusArrivalDto.fromJson(JsonMap json) {
    return BatumiRouteBusArrivalDto(
      busId: _string(json['bus_id']),
      busName: _string(json['bus_name']),
      minute: _int(json['minute']),
    );
  }
}

List<BatumiRouteBusArrivalDto> _parseArrivalTimes(Object? raw) {
  final map = _objectMap(raw);
  if (map == null) {
    return const [];
  }
  return map.values
      .map(_objectMap)
      .whereType<JsonMap>()
      .map(BatumiRouteBusArrivalDto.fromJson)
      .where((arrival) => arrival.minute > 0)
      .toList(growable: false);
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

String _string(Object? raw) => raw == null ? '' : '$raw';
