import 'package:equatable/equatable.dart';

enum RouteResultStepType { point, walk, zone }

class RouteResultStep extends Equatable {
  const RouteResultStep({
    required this.type,
    required this.label,
    this.meters,
    this.minutes,
  });

  const RouteResultStep.point({
    required this.label,
  })  : type = RouteResultStepType.point,
        meters = null,
        minutes = null;

  const RouteResultStep.walk({
    required this.label,
    this.meters,
    this.minutes,
  }) : type = RouteResultStepType.walk;

  const RouteResultStep.zone({
    required this.label,
  })  : type = RouteResultStepType.zone,
        meters = null,
        minutes = null;

  final RouteResultStepType type;
  final String label;
  final int? meters;
  final int? minutes;

  @override
  List<Object?> get props => [type, label, meters, minutes];
}
