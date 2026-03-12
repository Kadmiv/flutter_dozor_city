import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_dozor_city/core/domain/entities/arrival_info.dart';
import 'package:flutter_dozor_city/core/domain/entities/city.dart';
import 'package:flutter_dozor_city/core/domain/entities/route_zone.dart';
import 'package:flutter_dozor_city/core/domain/entities/transport_route.dart';
import 'package:flutter_dozor_city/core/domain/repositories/city_repository.dart';
import 'package:flutter_dozor_city/core/domain/repositories/session_repository.dart';
import 'package:flutter_dozor_city/core/map/app_map_camera.dart';
import 'package:flutter_dozor_city/features/live_tracking/domain/entities/vehicle_entity.dart';
import 'package:flutter_dozor_city/features/main_map/domain/usecases/check_city_data_freshness_use_case.dart';
import 'package:flutter_dozor_city/features/main_map/presentation/bloc/main_map_cubit.dart';

class _FakeSessionRepository extends SessionRepository {
  _FakeSessionRepository({required this.city});

  final City city;
  final Map<String, bool> _uiFlags = {};
  final Map<String, AppMapCamera> _cameras = {};

  @override
  City? get selectedCity => city;

  @override
  bool get hasSelectedCity => true;

  @override
  Future<AppMapCamera?> getMapCamera(String cityId) async => _cameras[cityId];

  @override
  Future<int?> getRoutesCacheHash(String cityId) async => null;

  @override
  Future<bool> getUiFlag(String key) async => _uiFlags[key] ?? false;

  @override
  Future<void> setMapCamera(String cityId, AppMapCamera camera) async {
    _cameras[cityId] = camera;
  }

  @override
  Future<void> setRoutesCacheHash(String cityId, int hash) async {}

  @override
  Future<void> setSelectedCity(City city) async {}

  @override
  Future<void> setUiFlag(String key, bool value) async {
    _uiFlags[key] = value;
  }
}

class _FakeCityRepository implements CityRepository {
  int freshnessChecks = 0;

  @override
  Future<bool> ensureCityDataFresh(String cityId) async {
    freshnessChecks += 1;
    return true;
  }

  @override
  Future<ArrivalInfo> getArrivalByZone({
    required String cityId,
    required String zoneId,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<List<City>> getCities() async => const [];

  @override
  Future<List<VehicleEntity>> getCityVehicles(String cityId) async => const [];

  @override
  Future<List<RouteZone>> getRouteZones(String routeId) async => const [];

  @override
  Future<List<TransportRoute>> getRoutesByType({
    required String cityId,
    required int transportType,
  }) async => const [];

  @override
  Future<void> preloadCityData(String cityId) async {}
}

void main() {
  group('MainMapCubit', () {
    const city = City(
      id: 'zhytomyr',
      name: 'Житомир',
      region: 'Житомирська область',
      centerLat: 50.25465,
      centerLng: 28.65867,
      zoom: 12.5,
    );

    test('refresh loads camera and dismissed hints from session', () async {
      final session = _FakeSessionRepository(city: city);
      final repository = _FakeCityRepository();
      await session.setUiFlag('select-city', true);
      await session.setUiFlag('arrival', true);
      await session.setMapCamera(
        city.id,
        const AppMapCamera(centerLat: 50.3, centerLng: 28.7, zoom: 14),
      );
      final cubit = MainMapCubit(
        sessionRepository: session,
        checkCityDataFreshnessUseCase:
            CheckMainMapCityDataFreshnessUseCase(repository),
      );

      await cubit.refresh();

      expect(repository.freshnessChecks, 1);
      expect(cubit.state.city, city);
      expect(cubit.state.camera, const AppMapCamera(centerLat: 50.3, centerLng: 28.7, zoom: 14));
      expect(cubit.state.dismissedHints, containsAll(<String>{'select-city', 'arrival'}));
      expect(cubit.state.dismissedHints, isNot(contains('map-menu')));
    });

    test('dismissHint persists flag in session and updates state', () async {
      final session = _FakeSessionRepository(city: city);
      final cubit = MainMapCubit(
        sessionRepository: session,
        checkCityDataFreshnessUseCase:
            CheckMainMapCityDataFreshnessUseCase(_FakeCityRepository()),
      );

      await cubit.dismissHint('map-menu');

      expect(cubit.state.dismissedHints, contains('map-menu'));
      expect(await session.getUiFlag('map-menu'), isTrue);
    });

    test('openBottomSheet(search) forces routes mode and toggleMarkers updates label', () {
      final cubit = MainMapCubit(
        sessionRepository: _FakeSessionRepository(city: city),
        checkCityDataFreshnessUseCase:
            CheckMainMapCityDataFreshnessUseCase(_FakeCityRepository()),
      );

      cubit.setRouteMode(MainMapMode.city);
      cubit.openBottomSheet(tab: MainMapTab.search);
      cubit.toggleMarkers();

      expect(cubit.state.currentTab, MainMapTab.search);
      expect(cubit.state.mode, MainMapMode.routes);
      expect(cubit.state.isBottomSheetVisible, isTrue);
      expect(cubit.state.showMarkers, isFalse);
      expect(cubit.state.activeMapActionLabel, 'Маркери приховані');
    });
  });
}
