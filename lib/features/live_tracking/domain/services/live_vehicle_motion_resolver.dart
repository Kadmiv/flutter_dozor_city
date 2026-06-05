import 'dart:math' as math;

import 'package:flutter_dozor_city/core/domain/entities/vehicle.dart';
import 'package:flutter_dozor_city/features/live_tracking/domain/entities/animated_vehicle.dart';

class LiveVehicleMotionResolver {
  const LiveVehicleMotionResolver({
    this.defaultDuration = const Duration(seconds: 10),
    this.minDuration = const Duration(milliseconds: 800),
    this.maxDuration = const Duration(seconds: 12),
    this.minAnimatedDistanceMeters = 3,
    this.maxUrbanSpeedKmh = 90,
  });

  final Duration defaultDuration;
  final Duration minDuration;
  final Duration maxDuration;
  final double minAnimatedDistanceMeters;
  final double maxUrbanSpeedKmh;

  List<AnimatedVehicle> resolve({
    required List<AnimatedVehicle> previous,
    required List<Vehicle> next,
    required DateTime now,
    DateTime? previousUpdatedAt,
  }) {
    final previousById = {
      for (final vehicle in previous) vehicle.vehicle.id: vehicle,
    };
    final transitionDuration = _transitionDuration(
      now: now,
      previousUpdatedAt: previousUpdatedAt,
    );

    return next
        .map(
          (vehicle) => _resolveVehicle(
            previous: previousById[vehicle.id],
            next: vehicle,
            now: now,
            transitionDuration: transitionDuration,
          ),
        )
        .toList(growable: false);
  }

  AnimatedVehicle _resolveVehicle({
    required AnimatedVehicle? previous,
    required Vehicle next,
    required DateTime now,
    required Duration transitionDuration,
  }) {
    if (previous == null) {
      return _snap(next: next, now: now, calculatedSpeedKmh: next.speed);
    }

    final current = previous.vehicleAt(now);
    final distanceMeters = _distanceMeters(
      current.lat,
      current.lng,
      next.lat,
      next.lng,
    );
    final elapsedSeconds = transitionDuration.inMilliseconds / 1000.0;
    final calculatedSpeed = elapsedSeconds <= 0
        ? 0
        : ((distanceMeters / elapsedSeconds) * 3.6).round();
    final shouldSnap =
        next.routeId != current.routeId ||
        next.transportType != current.transportType ||
        distanceMeters < minAnimatedDistanceMeters ||
        calculatedSpeed > maxUrbanSpeedKmh;

    if (shouldSnap) {
      return _snap(
        next: next,
        now: now,
        calculatedSpeedKmh: next.speed > 0 ? next.speed : 0,
      );
    }

    return AnimatedVehicle(
      vehicle: next.copyWith(
        speed: next.speed > 0 ? next.speed : calculatedSpeed,
      ),
      fromLat: current.lat,
      fromLng: current.lng,
      toLat: next.lat,
      toLng: next.lng,
      startedAt: now,
      duration: transitionDuration,
      calculatedSpeedKmh: calculatedSpeed,
      isPredicted: true,
    );
  }

  AnimatedVehicle _snap({
    required Vehicle next,
    required DateTime now,
    required int calculatedSpeedKmh,
  }) {
    return AnimatedVehicle(
      vehicle: next.copyWith(
        speed: next.speed > 0 ? next.speed : calculatedSpeedKmh,
      ),
      fromLat: next.lat,
      fromLng: next.lng,
      toLat: next.lat,
      toLng: next.lng,
      startedAt: now,
      duration: Duration.zero,
      calculatedSpeedKmh: calculatedSpeedKmh,
      isPredicted: false,
    );
  }

  Duration _transitionDuration({
    required DateTime now,
    required DateTime? previousUpdatedAt,
  }) {
    final raw = previousUpdatedAt == null
        ? defaultDuration
        : now.difference(previousUpdatedAt);
    if (raw <= Duration.zero) {
      return defaultDuration;
    }
    if (raw < minDuration) {
      return minDuration;
    }
    if (raw > maxDuration) {
      return maxDuration;
    }
    return raw;
  }

  double _distanceMeters(
    double startLat,
    double startLng,
    double endLat,
    double endLng,
  ) {
    final lat1 = _radians(startLat);
    final lat2 = _radians(endLat);
    final deltaLat = _radians(endLat - startLat);
    final deltaLng = _radians(endLng - startLng);
    final a =
        math.sin(deltaLat / 2) * math.sin(deltaLat / 2) +
        math.cos(lat1) *
            math.cos(lat2) *
            math.sin(deltaLng / 2) *
            math.sin(deltaLng / 2);
    final c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
    return _earthRadiusMeters * c;
  }

  double _radians(double degrees) => degrees * math.pi / 180.0;

  static const double _earthRadiusMeters = 6371000.0;
}
