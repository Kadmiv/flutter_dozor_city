import 'package:equatable/equatable.dart';

class VehicleEntity extends Equatable {
  const VehicleEntity({
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
