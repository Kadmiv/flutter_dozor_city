import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_dozor_city/core/data/datasources/local/city_local_data_source.dart';
import 'package:flutter_dozor_city/core/data/datasources/remote/city_remote_data_source.dart';
import 'package:flutter_dozor_city/core/data/repositories/city_repository_impl.dart';
import 'package:flutter_dozor_city/core/domain/entities/arrival_info.dart';
import 'package:flutter_dozor_city/core/domain/entities/city.dart';
import 'package:flutter_dozor_city/core/domain/entities/route_zone.dart';
import 'package:flutter_dozor_city/core/domain/entities/transport_route.dart';
import 'package:flutter_dozor_city/core/domain/repositories/session_repository.dart';
import 'package:flutter_dozor_city/core/map/app_map_camera.dart';
import 'package:flutter_dozor_city/features/live_tracking/domain/entities/vehicle_entity.dart';

class _FakeCityLocalDataSource implements CityLocalDataSource {
  List<City> cities = const [];
  DateTime? citiesUpdatedAt;
  final Map<String, List<TransportRoute>> routesByType = {};
  final Map<String, DateTime> routesUpdatedAt = {};
  final Map<String, List<RouteZone>> zonesByRoute = {};
  final Map<String, DateTime> zonesUpdatedAt = {};
  final Map<String, ArrivalInfo> arrivals = {};
  final Map<String, DateTime> arrivalsUpdatedAt = {};

  @override
  Future<void> clearCityData(String cityId) async {}

  @override
  Future<ArrivalInfo?> getArrivalByZone(String zoneId) async => arrivals[zoneId];

  @override
  Future<DateTime?> getArrivalUpdatedAt(String zoneId) async =>
      arrivalsUpdatedAt[zoneId];

  @override
  Future<List<City>> getCities() async => cities;

  @override
  Future<DateTime?> getCitiesUpdatedAt() async => citiesUpdatedAt;

  @override
  Future<List<RouteZone>> getRouteZones(String routeId) async => const [];
 
  @override
  Future<DateTime?> getRouteZonesUpdatedAt(String routeId) async =>
      zonesUpdatedAt[routeId];

  @override
  Future<List<TransportRoute>> getRoutesByType({
    required String cityId,
    required int transportType,
  }) async => routesByType['$cityId:$transportType'] ?? const [];

  @override
  Future<DateTime?> getRoutesByTypeUpdatedAt({
    required String cityId,
    required int transportType,
  }) async => routesUpdatedAt['$cityId:$transportType'];

  @override
  Future<void> saveArrivalByZone(ArrivalInfo arrivalInfo) async {
    arrivals[arrivalInfo.zoneId] = arrivalInfo;
    arrivalsUpdatedAt[arrivalInfo.zoneId] = DateTime.now();
  }

  @override
  Future<void> saveCities(List<City> cities) async {
    this.cities = cities;
    citiesUpdatedAt = DateTime.now();
  }

  @override
  Future<void> saveRouteZones(String routeId, List<RouteZone> zones) async {
    zonesByRoute[routeId] = zones;
    zonesUpdatedAt[routeId] = DateTime.now();
  }

  @override
  Future<void> saveRoutesByType({
    required String cityId,
    required int transportType,
    required List<TransportRoute> routes,
  }) async {
    routesByType['$cityId:$transportType'] = routes;
    routesUpdatedAt['$cityId:$transportType'] = DateTime.now();
  }
}

class _FakeCityRemoteDataSource implements CityRemoteDataSource {
  int arrivalCalls = 0;
  int routesCalls = 0;
  ArrivalInfo arrival = const ArrivalInfo(
    zoneId: 'zone-1',
    busMinutes: [3],
    trolleyMinutes: [7],
    tramMinutes: [11],
  );

  @override
  Future<ArrivalInfo> getArrivalByZone({
    required String cityId,
    required String zoneId,
  }) async {
    arrivalCalls += 1;
    return arrival;
  }

  @override
  Future<int> getCityDataHash(String cityId) async => 1;

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
  }) async {
    routesCalls += 1;
    return const [
      TransportRoute(
        id: 'route-a',
        shortName: '1A',
        title: 'Маршрут 1A',
        transportType: 0,
      ),
    ];
  }

  @override
  Future<void> preloadCityData(String cityId) async {}
}

class _FakeSessionRepository extends SessionRepository {
  final Map<String, bool> _uiFlags = {};

  @override
  City? get selectedCity => null;

  @override
  bool get hasSelectedCity => false;

  @override
  Future<AppMapCamera?> getMapCamera(String cityId) async => null;

  @override
  Future<int?> getRoutesCacheHash(String cityId) async => null;

  @override
  Future<bool> getUiFlag(String key) async => _uiFlags[key] ?? false;

  @override
  Future<void> setMapCamera(String cityId, AppMapCamera camera) async {}

  @override
  Future<void> setRoutesCacheHash(String cityId, int hash) async {}

  @override
  Future<void> setSelectedCity(City city) async {}

  @override
  Future<void> setUiFlag(String key, bool value) async {
    _uiFlags[key] = value;
  }
}

void main() {
  group('CityRepositoryImpl', () {
    test('returns fresh cached arrival without hitting remote', () async {
      final local = _FakeCityLocalDataSource();
      const cachedArrival = ArrivalInfo(
        zoneId: 'zone-1',
        busMinutes: [1, 2],
        trolleyMinutes: [4],
        tramMinutes: [9],
      );
      local.arrivals['zone-1'] = cachedArrival;
      local.arrivalsUpdatedAt['zone-1'] = DateTime.now();

      final remote = _FakeCityRemoteDataSource();
      final repository = CityRepositoryImpl(
        remoteDataSource: remote,
        localDataSource: local,
        sessionRepository: _FakeSessionRepository(),
      );

      final result = await repository.getArrivalByZone(
        cityId: 'zhytomyr',
        zoneId: 'zone-1',
      );

      expect(result, cachedArrival);
      expect(remote.arrivalCalls, 0);
    });

    test('returns fresh cached routes without hitting remote', () async {
      final local = _FakeCityLocalDataSource();
      const cachedRoutes = [
        TransportRoute(
          id: 'route-a',
          shortName: '1A',
          title: 'Маршрут 1A',
          transportType: 0,
        ),
      ];
      local.routesByType['zhytomyr:0'] = cachedRoutes;
      local.routesUpdatedAt['zhytomyr:0'] = DateTime.now();

      final remote = _FakeCityRemoteDataSource();
      final repository = CityRepositoryImpl(
        remoteDataSource: remote,
        localDataSource: local,
        sessionRepository: _FakeSessionRepository(),
      );

      final result = await repository.getRoutesByType(
        cityId: 'zhytomyr',
        transportType: 0,
      );

      expect(result, cachedRoutes);
      expect(remote.routesCalls, 0);
    });
  });
}
