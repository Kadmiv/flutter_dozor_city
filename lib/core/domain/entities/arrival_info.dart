import 'package:equatable/equatable.dart';
import 'package:flutter_dozor_city/core/domain/entities/route_arrival.dart';

class ArrivalInfo extends Equatable {
  const ArrivalInfo({
    required this.zoneId,
    required this.busMinutes,
    required this.trolleyMinutes,
    required this.tramMinutes,
    this.routeArrivals = const [],
  });

  final String zoneId;
  final List<int> busMinutes;
  final List<int> trolleyMinutes;
  final List<int> tramMinutes;
  final List<RouteArrival> routeArrivals;

  @override
  List<Object> get props => [
    zoneId,
    busMinutes,
    trolleyMinutes,
    tramMinutes,
    routeArrivals,
  ];
}
