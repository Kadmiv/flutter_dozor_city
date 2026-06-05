import 'package:flutter_dozor_city/core/domain/entities/arrival_info.dart';

class ArrivalInfoDto {
  const ArrivalInfoDto({
    required this.zoneId,
    required this.busMinutes,
    required this.trolleyMinutes,
    required this.tramMinutes,
  });

  final String zoneId;
  final List<int> busMinutes;
  final List<int> trolleyMinutes;
  final List<int> tramMinutes;

  factory ArrivalInfoDto.fromJson(Map<String, Object?> json) {
    return ArrivalInfoDto(
      zoneId: _string(json['zoneId']),
      busMinutes: _parseList(json['busMinutes'] ?? json['a1']),
      trolleyMinutes: _parseList(json['trolleyMinutes'] ?? json['a2']),
      tramMinutes: _parseList(json['tramMinutes'] ?? json['a3']),
    );
  }

  ArrivalInfo toEntity() {
    return ArrivalInfo(
      zoneId: zoneId,
      busMinutes: busMinutes,
      trolleyMinutes: trolleyMinutes,
      tramMinutes: tramMinutes,
    );
  }
}

typedef ArrivalInfoModel = ArrivalInfoDto;

List<int> _parseList(Object? raw) {
  if (raw is! List) {
    return const [];
  }
  final result = <int>[];
  for (final item in raw) {
    final value = _parseMinute(item);
    if (value > 0) {
      result.add(value);
    }
  }
  return result;
}

int _parseMinute(Object? raw) {
  if (raw is num) {
    return raw.toInt();
  }
  if (raw is Map) {
    final value = raw['t'];
    if (value is num) {
      return value.toInt();
    }
    return int.tryParse('$value') ?? 0;
  }
  return int.tryParse('$raw') ?? 0;
}

String _string(Object? raw) => raw == null ? '' : '$raw';
