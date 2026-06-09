import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_dozor_city/core/domain/entities/arrival_info.dart';
import 'package:flutter_dozor_city/core/domain/entities/city.dart';
import 'package:flutter_dozor_city/core/domain/entities/app_lat_lng.dart';
import 'package:flutter_dozor_city/core/domain/entities/route_zone.dart';
import 'package:flutter_dozor_city/core/domain/entities/transport_route.dart';
import 'package:flutter_dozor_city/core/domain/entities/vehicle.dart';
import 'package:flutter_dozor_city/core/domain/repositories/city_repository.dart';
import 'package:flutter_dozor_city/core/time/app_clock.dart';
import 'package:flutter_dozor_city/core/time/polling_scheduler.dart';
import 'package:flutter_dozor_city/features/live_tracking/domain/usecases/get_city_vehicles_use_case.dart';
import 'package:flutter_dozor_city/features/live_tracking/presentation/bloc/live_tracking_cubit.dart';

void main() {
  group('LiveTrackingBloc', () {
    test('calculates speed after second response', () async {
      final repository = _FakeCityRepository([
        [_vehicle(lat: 41, lng: 41, speed: 0)],
        [_vehicle(lat: 41.0001, lng: 41.0001, speed: 0)],
      ]);
      final clock = _FakeClock(DateTime(2026, 1, 1, 12));
      final cubit = LiveTrackingBloc(
        getCityVehiclesUseCase: GetCityVehiclesUseCase(repository),
        pollingScheduler: _FakePollingScheduler(),
        clock: clock,
      );

      await cubit.start('batumi', routeIds: const ['route-1']);
      expect(cubit.state.animatedVehicles.single.calculatedSpeedKmh, 0);

      clock.advance(const Duration(seconds: 10));
      await cubit.updateFilters(const ['route-1']);

      expect(cubit.state.routeIds, const ['route-1']);
      expect(
        cubit.state.animatedVehicles.single.calculatedSpeedKmh,
        greaterThan(0),
      );
      expect(cubit.state.animatedVehicles.single.vehicle.speed, greaterThan(0));

      await cubit.close();
    });

    test('uses API speed for display when it is available', () async {
      final repository = _FakeCityRepository([
        [_vehicle(lat: 41, lng: 41, speed: 24)],
        [_vehicle(lat: 41.0001, lng: 41.0001, speed: 25)],
      ]);
      final clock = _FakeClock(DateTime(2026, 1, 1, 12));
      final cubit = LiveTrackingBloc(
        getCityVehiclesUseCase: GetCityVehiclesUseCase(repository),
        pollingScheduler: _FakePollingScheduler(),
        clock: clock,
      );

      await cubit.start('dozor');
      clock.advance(const Duration(seconds: 10));
      await cubit.updateFilters(null);

      expect(
        cubit.state.animatedVehicles.single.calculatedSpeedKmh,
        greaterThan(0),
      );
      expect(cubit.state.animatedVehicles.single.vehicle.speed, 25);

      await cubit.close();
    });
  });
}

class _FakeCityRepository implements CityRepository {
  _FakeCityRepository(this.responses);

  final List<List<Vehicle>> responses;
  int calls = 0;

  @override
  Future<List<Vehicle>> getCityVehicles(
    String cityId, {
    List<String>? routeIds,
  }) async {
    final index = calls.clamp(0, responses.length - 1).toInt();
    calls += 1;
    return responses[index];
  }

  @override
  Future<bool> ensureCityDataFresh(String cityId) async => true;

  @override
  Future<ArrivalInfo> getArrivalByZone({
    required String cityId,
    required String zoneId,
  }) async {
    return ArrivalInfo(
      zoneId: zoneId,
      busMinutes: const [],
      trolleyMinutes: const [],
      tramMinutes: const [],
    );
  }

  @override
  Future<List<City>> getCities() async => const [];

  @override
  Future<List<TransportRoute>> getRoutesByType({
    required String cityId,
    required int transportType,
  }) async {
    return const [];
  }

  @override
  Future<List<RouteZone>> getRouteZones(String routeId) async => const [];

  @override
  Future<List<RouteZone>> getCityStops(String cityId) async => const [
    RouteZone(
      id: 'stop-1',
      routeId: 'route-1',
      name: 'Зупинка 1',
      position: AppLatLng(lat: 50.25, lng: 28.66),
    ),
  ];

  @override
  Future<void> preloadCityData(String cityId) async {}
}

class _FakeClock implements AppClock {
  _FakeClock(this.value);

  DateTime value;

  void advance(Duration duration) {
    value = value.add(duration);
  }

  @override
  DateTime now() => value;
}

class _FakePollingScheduler implements PollingScheduler {
  @override
  void start(Duration interval, FutureOr<void> Function() action) {}

  @override
  void stop() {}
}

Vehicle _vehicle({double lat = 41, double lng = 41, int speed = 0}) {
  return Vehicle(
    id: 'bus-1',
    routeId: 'route-1',
    routeShortName: '1',
    routeTitle: 'Route 1',
    transportType: 0,
    lat: lat,
    lng: lng,
    azimuth: 45,
    speed: speed,
    govNumber: 'BUS-1',
  );
}
