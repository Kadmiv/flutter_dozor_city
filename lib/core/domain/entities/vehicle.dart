import 'package:equatable/equatable.dart';

class Vehicle extends Equatable {
  const Vehicle({
    required this.id,
    required this.routeId,
    required this.routeShortName,
    required this.routeTitle,
    required this.transportType,
    required this.lat,
    required this.lng,
    required this.azimuth,
    required this.speed,
    required this.govNumber,
  });

  final String id;
  final String routeId;
  final String routeShortName;
  final String routeTitle;
  final int transportType;
  final double lat;
  final double lng;
  final int azimuth;
  final int speed;
  final String govNumber;

  Vehicle copyWith({
    String? id,
    String? routeId,
    String? routeShortName,
    String? routeTitle,
    int? transportType,
    double? lat,
    double? lng,
    int? azimuth,
    int? speed,
    String? govNumber,
  }) {
    return Vehicle(
      id: id ?? this.id,
      routeId: routeId ?? this.routeId,
      routeShortName: routeShortName ?? this.routeShortName,
      routeTitle: routeTitle ?? this.routeTitle,
      transportType: transportType ?? this.transportType,
      lat: lat ?? this.lat,
      lng: lng ?? this.lng,
      azimuth: azimuth ?? this.azimuth,
      speed: speed ?? this.speed,
      govNumber: govNumber ?? this.govNumber,
    );
  }

  @override
  List<Object> get props => [
    id,
    routeId,
    routeShortName,
    routeTitle,
    transportType,
    lat,
    lng,
    azimuth,
    speed,
    govNumber,
  ];
}
