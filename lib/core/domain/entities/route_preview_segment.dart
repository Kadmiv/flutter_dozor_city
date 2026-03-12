import 'package:equatable/equatable.dart';

enum RoutePreviewSegmentType { walk, ride, transfer }

class RoutePreviewSegment extends Equatable {
  const RoutePreviewSegment({
    required this.type,
    required this.label,
    this.meters,
  });

  final RoutePreviewSegmentType type;
  final String label;
  final int? meters;

  @override
  List<Object?> get props => [type, label, meters];
}
