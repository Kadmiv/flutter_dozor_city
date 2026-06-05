import 'package:equatable/equatable.dart';
import 'package:flutter_dozor_city/core/domain/entities/vehicle.dart';

class AnimatedVehicle extends Equatable {
  const AnimatedVehicle({
    required this.vehicle,
    required this.fromLat,
    required this.fromLng,
    required this.toLat,
    required this.toLng,
    required this.startedAt,
    required this.duration,
    required this.calculatedSpeedKmh,
    required this.isPredicted,
  });

  final Vehicle vehicle;
  final double fromLat;
  final double fromLng;
  final double toLat;
  final double toLng;
  final DateTime startedAt;
  final Duration duration;
  final int calculatedSpeedKmh;
  final bool isPredicted;

  Vehicle vehicleAt(DateTime now) {
    final progress = progressAt(now);
    return vehicle.copyWith(
      lat: _lerp(fromLat, toLat, progress),
      lng: _lerp(fromLng, toLng, progress),
      speed: displaySpeedKmh,
    );
  }

  int get displaySpeedKmh {
    if (vehicle.speed > 0) {
      return vehicle.speed;
    }
    return calculatedSpeedKmh;
  }

  double progressAt(DateTime now) {
    if (duration.inMilliseconds <= 0) {
      return 1;
    }
    final elapsed = now.difference(startedAt).inMilliseconds;
    return (elapsed / duration.inMilliseconds).clamp(0.0, 1.0);
  }

  bool get isMoving {
    return duration.inMilliseconds > 0 &&
        ((fromLat - toLat).abs() > _epsilon ||
            (fromLng - toLng).abs() > _epsilon);
  }

  double _lerp(double start, double end, double progress) {
    return start + ((end - start) * progress);
  }

  @override
  List<Object?> get props => [
    vehicle,
    fromLat,
    fromLng,
    toLat,
    toLng,
    startedAt,
    duration,
    calculatedSpeedKmh,
    isPredicted,
  ];

  static const double _epsilon = 0.0000001;
}
