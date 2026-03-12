import 'package:equatable/equatable.dart';

enum SelectedPointSource { zone, gps, address, mapTap }

class SelectedPoint extends Equatable {
  const SelectedPoint({
    required this.label,
    required this.lat,
    required this.lng,
    required this.source,
    this.zoneId,
  });

  final String label;
  final double lat;
  final double lng;
  final SelectedPointSource source;
  final int? zoneId;

  @override
  List<Object?> get props => [label, lat, lng, source, zoneId];
}
