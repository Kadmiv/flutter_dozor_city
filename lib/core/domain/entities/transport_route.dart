import 'package:equatable/equatable.dart';
import 'package:flutter_dozor_city/core/domain/entities/app_lat_lng.dart';

class TransportRoute extends Equatable {
  const TransportRoute({
    required this.id,
    required this.shortName,
    required this.title,
    required this.transportType,
    this.polylineSegments = const [],
    this.lineColorValue = 0xFF1C4F7A,
  });

  final String id;
  final String shortName;
  final String title;
  final int transportType;
  final List<List<AppLatLng>> polylineSegments;
  final int lineColorValue;

  @override
  List<Object> get props => [
        id,
        shortName,
        title,
        transportType,
        polylineSegments,
        lineColorValue,
      ];
}
