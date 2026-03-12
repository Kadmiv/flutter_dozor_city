import 'package:equatable/equatable.dart';

class AppMapCamera extends Equatable {
  const AppMapCamera({
    required this.centerLat,
    required this.centerLng,
    required this.zoom,
  });

  final double centerLat;
  final double centerLng;
  final double zoom;

  @override
  List<Object> get props => [centerLat, centerLng, zoom];
}
