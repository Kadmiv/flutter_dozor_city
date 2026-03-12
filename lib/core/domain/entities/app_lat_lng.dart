import 'package:equatable/equatable.dart';

class AppLatLng extends Equatable {
  const AppLatLng({
    required this.lat,
    required this.lng,
  });

  final double lat;
  final double lng;

  @override
  List<Object> get props => [lat, lng];
}
