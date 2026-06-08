import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_dozor_city/core/domain/entities/city.dart';
import 'package:flutter_dozor_city/core/domain/entities/app_lat_lng.dart';
import 'package:flutter_dozor_city/core/domain/repositories/session_repository.dart';
import 'package:flutter_dozor_city/core/map/app_map_camera.dart';
import 'package:flutter_dozor_city/core/time/app_clock.dart';
import 'package:flutter_dozor_city/features/city_data/data/datasources/local/city_local_data_source.dart';
import 'package:flutter_dozor_city/features/city_data/data/datasources/remote/city_remote_data_source.dart';
import 'package:flutter_dozor_city/features/city_data/data/repositories/city_repository_impl.dart';
import 'package:flutter_dozor_city/features/city_data/data/batumi/batumi_city_catalog.dart';
import 'package:flutter_dozor_city/core/domain/entities/arrival_info.dart';
import 'package:flutter_dozor_city/core/domain/entities/route_zone.dart';
import 'package:flutter_dozor_city/core/domain/entities/selected_map_routes.dart';
import 'package:flutter_dozor_city/core/domain/entities/transport_route.dart';
import 'package:flutter_dozor_city/core/domain/entities/vehicle.dart';

class _FakeLocalDataSource implements CityLocalDataSource {
  List<City> cities = const [];
  DateTime? citiesUpdatedAt;

  @override
  Future<void> clearCityData(String cityId) async {}

  @override
  Future<ArrivalInfo?> getArrivalByZone(String zoneId) async => null;

  @override
  Future<DateTime?> getArrivalUpdatedAt(String zoneId) async => null;

  @override
  Future<List<City>> getCities() async => cities;

  @override
  Future<DateTime?> getCitiesUpdatedAt() async => citiesUpdatedAt;

  @override
  Future<List<RouteZone>> getRouteZones(String routeId) async => const [];

  @override
  Future<DateTime?> getCityStopsUpdatedAt(String cityId) async => null;

  @override
  Future<List<RouteZone>> getCityStops(String cityId) async => const [];

  @override
  Future<DateTime?> getRouteZonesUpdatedAt(String routeId) async => null;

  @override
  Future<List<TransportRoute>> getRoutesByType({
    required String cityId,
    required int transportType,
  }) async => const [];

  @override
  Future<DateTime?> getRoutesByTypeUpdatedAt({
    required String cityId,
    required int transportType,
  }) async => null;

  @override
  Future<void> saveArrivalByZone(ArrivalInfo arrivalInfo) async {}

  @override
  Future<void> saveCities(List<City> cities) async {
    this.cities = cities;
    citiesUpdatedAt = DateTime.now();
  }

  @override
  Future<void> saveRouteZones(String routeId, List<RouteZone> zones) async {}

  @override
  Future<void> saveCityStops(String cityId, List<RouteZone> stops) async {}

  @override
  Future<void> saveRoutesByType({
    required String cityId,
    required int transportType,
    required List<TransportRoute> routes,
  }) async {}
}

class _FakeRemoteDataSource implements CityRemoteDataSource {
  @override
  Future<List<City>> getCities() async => const [
    City(
      id: 'kyiv',
      name: 'Kyiv',
      region: 'Kyiv',
      centerLat: 50.45,
      centerLng: 30.52,
      zoom: 11,
    ),
  ];

  @override
  Future<int> getCityDataHash(String cityId) async => 1;

  @override
  Future<List<Vehicle>> getCityVehicles(
    String cityId, {
    List<String>? routeIds,
  }) async => const [];

  @override
  Future<ArrivalInfo> getArrivalByZone({
    required String cityId,
    required String zoneId,
  }) async => const ArrivalInfo(
    zoneId: 'zone',
    busMinutes: [],
    trolleyMinutes: [],
    tramMinutes: [],
  );

  @override
  Future<List<RouteZone>> getRouteZones(String routeId) async => const [];

  @override
  Future<List<RouteZone>> getCityStops(String cityId) async => const [
    RouteZone(
      id: 'stop-1',
      routeId: 'route-1',
      name: 'Зупинка 1',
      position: AppLatLng(lat: 41.6168, lng: 41.6367),
    ),
  ];

  @override
  Future<List<TransportRoute>> getRoutesByType({
    required String cityId,
    required int transportType,
  }) async => const [];

  @override
  Future<void> preloadCityData(String cityId) async {}
}

class _FakeSessionRepository extends SessionRepository {
  @override
  City? get selectedCity => null;

  @override
  bool get hasSelectedCity => false;

  @override
  Future<AppMapCamera?> getMapCamera(String cityId) async => null;

  @override
  Future<int?> getRoutesCacheHash(String cityId) async => null;

  @override
  Future<SelectedMapRoutes?> getSelectedMapRoutes(String cityId) async => null;

  @override
  Future<bool> getUiFlag(String key) async => false;

  @override
  Future<void> setMapCamera(String cityId, AppMapCamera camera) async {}

  @override
  Future<void> setRoutesCacheHash(String cityId, int hash) async {}

  @override
  Future<void> setSelectedMapRoutes(
    String cityId,
    SelectedMapRoutes selectedMapRoutes,
  ) async {}

  @override
  Future<void> setSelectedCity(City city) async {}

  @override
  Future<void> setUiFlag(String key, bool value) async {}

  @override
  Future<String?> getMapLanguage() async => null;

  @override
  Future<void> setMapLanguage(String languageCode) async {}
}

void main() {
  test('appends Batumi city to cached city list', () async {
    final local = _FakeLocalDataSource()
      ..cities = const [
        City(
          id: 'kyiv',
          name: 'Kyiv',
          region: 'Kyiv',
          centerLat: 50.45,
          centerLng: 30.52,
          zoom: 11,
        ),
      ]
      ..citiesUpdatedAt = DateTime.now();
    final repository = CityRepositoryImpl(
      remoteDataSource: _FakeRemoteDataSource(),
      localDataSource: local,
      sessionRepository: _FakeSessionRepository(),
      clock: const SystemClock(),
    );

    final cities = await repository.getCities();

    expect(
      cities.map((city) => city.id),
      containsAll(['kyiv', BatumiCityCatalog.cityId]),
    );
    expect(
      local.cities.map((city) => city.id),
      contains(BatumiCityCatalog.cityId),
    );
  });
}
