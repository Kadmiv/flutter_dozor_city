import 'package:equatable/equatable.dart';

class ArrivalInfo extends Equatable {
  const ArrivalInfo({
    required this.zoneId,
    required this.busMinutes,
    required this.trolleyMinutes,
    required this.tramMinutes,
  });

  final String zoneId;
  final List<int> busMinutes;
  final List<int> trolleyMinutes;
  final List<int> tramMinutes;

  @override
  List<Object> get props => [zoneId, busMinutes, trolleyMinutes, tramMinutes];
}
