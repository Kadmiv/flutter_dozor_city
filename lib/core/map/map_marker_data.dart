import 'package:equatable/equatable.dart';

class MapMarkerData extends Equatable {
  const MapMarkerData({
    required this.id,
    required this.lat,
    required this.lng,
    required this.rotation,
    required this.label,
  });

  final String id;
  final double lat;
  final double lng;
  final double rotation;
  final String label;

  @override
  List<Object> get props => [id, lat, lng, rotation, label];
}
