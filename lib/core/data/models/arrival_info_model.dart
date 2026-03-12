import 'package:flutter_dozor_city/core/domain/entities/arrival_info.dart';

class ArrivalInfoModel {
  const ArrivalInfoModel({
    required this.zoneId,
    required this.busMinutes,
    required this.trolleyMinutes,
    required this.tramMinutes,
  });

  final String zoneId;
  final List<int> busMinutes;
  final List<int> trolleyMinutes;
  final List<int> tramMinutes;

  factory ArrivalInfoModel.fromJson(Map<String, dynamic> json) {
    List<int> parseList(dynamic raw) {
      if (raw is! List) {
        return const [];
      }
      return raw
          .map(
            (item) => switch (item) {
              final num value => value.toInt(),
              final Map map => (map['t'] as num? ?? 0).toInt(),
              _ => 0,
            },
          )
          .where((value) => value > 0)
          .toList(growable: false);
    }

    return ArrivalInfoModel(
      zoneId: '${json['zoneId'] ?? ''}',
      busMinutes: parseList(json['busMinutes'] ?? json['a1']),
      trolleyMinutes: parseList(json['trolleyMinutes'] ?? json['a2']),
      tramMinutes: parseList(json['tramMinutes'] ?? json['a3']),
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
