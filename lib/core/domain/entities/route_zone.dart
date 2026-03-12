import 'package:equatable/equatable.dart';

class RouteZone extends Equatable {
  const RouteZone({
    required this.id,
    required this.routeId,
    required this.name,
  });

  final String id;
  final String routeId;
  final String name;

  @override
  List<Object> get props => [id, routeId, name];
}
