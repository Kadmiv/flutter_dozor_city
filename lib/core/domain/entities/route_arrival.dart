import 'package:equatable/equatable.dart';

class RouteArrival extends Equatable {
  const RouteArrival({
    required this.routeId,
    required this.routeShortName,
    required this.busId,
    required this.busName,
    required this.minute,
  });

  final String routeId;
  final String routeShortName;
  final String busId;
  final String busName;
  final int minute;

  @override
  List<Object> get props => [routeId, routeShortName, busId, busName, minute];
}
