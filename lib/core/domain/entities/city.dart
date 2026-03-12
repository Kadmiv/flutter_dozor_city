import 'package:equatable/equatable.dart';

class City extends Equatable {
  const City({
    required this.id,
    required this.name,
    required this.region,
    required this.centerLat,
    required this.centerLng,
    required this.zoom,
  });

  final String id;
  final String name;
  final String region;
  final double centerLat;
  final double centerLng;
  final double zoom;

  @override
  List<Object> get props => [id, name, region, centerLat, centerLng, zoom];
}
