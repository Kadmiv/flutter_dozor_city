import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_dozor_city/core/domain/entities/vehicle.dart';
import 'package:flutter_dozor_city/features/live_tracking/domain/entities/animated_vehicle.dart';
import 'package:flutter_dozor_city/features/live_tracking/domain/services/live_vehicle_motion_resolver.dart';

void main() {
  group('LiveVehicleMotionResolver', () {
    final now = DateTime(2026, 1, 1, 12);
    const resolver = LiveVehicleMotionResolver();

    test('first update creates snap state', () {
      final result = resolver.resolve(
        previous: const [],
        next: [_vehicle(lat: 41.1, lng: 41.1)],
        now: now,
      );

      expect(result, hasLength(1));
      expect(result.single.isPredicted, isFalse);
      expect(result.single.duration, Duration.zero);
      expect(result.single.vehicleAt(now).lat, 41.1);
    });

    test('second update calculates speed and transition', () {
      final first = resolver.resolve(
        previous: const [],
        next: [_vehicle(lat: 41, lng: 41)],
        now: now,
      );
      final second = resolver.resolve(
        previous: first,
        next: [_vehicle(lat: 41.0001, lng: 41.0001)],
        now: now.add(const Duration(seconds: 10)),
        previousUpdatedAt: now,
      );

      expect(second.single.isPredicted, isTrue);
      expect(second.single.duration, const Duration(seconds: 10));
      expect(second.single.calculatedSpeedKmh, greaterThan(0));
      expect(
        second.single.vehicleAt(now.add(const Duration(seconds: 15))).lat,
        closeTo(41.00005, 0.00002),
      );
    });

    test('large jumps snap instead of animating', () {
      final first = resolver.resolve(
        previous: const [],
        next: [_vehicle(lat: 41, lng: 41)],
        now: now,
      );
      final second = resolver.resolve(
        previous: first,
        next: [_vehicle(lat: 41.1, lng: 41.1)],
        now: now.add(const Duration(seconds: 10)),
        previousUpdatedAt: now,
      );

      expect(second.single.isPredicted, isFalse);
      expect(second.single.duration, Duration.zero);
      expect(second.single.vehicleAt(now).lat, 41.1);
    });

    test('missing vehicles are removed', () {
      final first = resolver.resolve(
        previous: const [],
        next: [
          _vehicle(id: 'bus-1'),
          _vehicle(id: 'bus-2'),
        ],
        now: now,
      );
      final second = resolver.resolve(
        previous: first,
        next: [_vehicle(id: 'bus-1')],
        now: now.add(const Duration(seconds: 10)),
        previousUpdatedAt: now,
      );

      expect(second.map((vehicle) => vehicle.vehicle.id), ['bus-1']);
    });

    test('new update starts from current interpolated position', () {
      final previous = AnimatedVehicle(
        vehicle: _vehicle(lat: 41, lng: 41.001, speed: 0),
        fromLat: 41,
        fromLng: 41,
        toLat: 41,
        toLng: 41.001,
        startedAt: now,
        duration: const Duration(seconds: 10),
        calculatedSpeedKmh: 30,
        isPredicted: true,
      );
      final second = resolver.resolve(
        previous: [previous],
        next: [_vehicle(lat: 41, lng: 41.0006)],
        now: now.add(const Duration(seconds: 5)),
        previousUpdatedAt: now,
      );

      expect(second.single.fromLng, closeTo(41.0005, 0.00002));
      expect(second.single.toLng, 41.0006);
    });
  });
}

Vehicle _vehicle({
  String id = 'bus-1',
  String routeId = 'route-1',
  int transportType = 0,
  double lat = 41,
  double lng = 41,
  int speed = 0,
}) {
  return Vehicle(
    id: id,
    routeId: routeId,
    routeShortName: '1',
    routeTitle: 'Route 1',
    transportType: transportType,
    lat: lat,
    lng: lng,
    azimuth: 45,
    speed: speed,
    govNumber: id,
  );
}
