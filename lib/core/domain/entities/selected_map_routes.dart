import 'package:equatable/equatable.dart';

class SelectedMapRoutes extends Equatable {
  const SelectedMapRoutes({
    required this.transportType,
    required this.selectedRouteIds,
    this.activeRouteId,
  });

  final int transportType;
  final List<String> selectedRouteIds;
  final String? activeRouteId;

  @override
  List<Object?> get props => [transportType, selectedRouteIds, activeRouteId];
}
