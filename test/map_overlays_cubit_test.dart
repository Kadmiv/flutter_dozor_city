import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_dozor_city/core/domain/entities/arrival_info.dart';
import 'package:flutter_dozor_city/core/domain/entities/city.dart';
import 'package:flutter_dozor_city/core/domain/entities/route_zone.dart';
import 'package:flutter_dozor_city/core/domain/entities/transport_route.dart';
import 'package:flutter_dozor_city/core/domain/repositories/city_repository.dart';
import 'package:flutter_dozor_city/features/live_tracking/domain/entities/vehicle_entity.dart';
import 'package:flutter_dozor_city/features/main_map/domain/usecases/get_arrival_by_zone_use_case.dart';
import 'package:flutter_dozor_city/features/main_map/domain/usecases/get_route_zones_use_case.dart';
import 'package:flutter_dozor_city/features/main_map/domain/usecases/get_routes_by_type_use_case.dart';
import 'package:flutter_dozor_city/features/main_map/presentation/bloc/map_overlays_cubit.dart';

class _FakeCityRepository implements CityRepository {
  final Map<int, List<TransportRoute>> routesByType = {
    0: const [
      TransportRoute(
        id: 'route-a',
        shortName: '1A',
        title: 'Маршрут 1A',
        transportType: 0,
      ),
      TransportRoute(
        id: 'route-b',
        shortName: '2B',
        title: 'Маршрут 2B',
        transportType: 0,
      ),
    ],
    1: const [
      TransportRoute(
        id: 'route-c',
        shortName: '3C',
        title: 'Маршрут 3C',
        transportType: 1,
      ),
    ],
  };

  final Map<String, List<RouteZone>> zonesByRoute = {
    'route-a': const [
      RouteZone(id: 'zone-a1', routeId: 'route-a', name: 'Зона A1'),
    ],
    'route-b': const [
      RouteZone(id: 'zone-b1', routeId: 'route-b', name: 'Зона B1'),
    ],
    'route-c': const [
      RouteZone(id: 'zone-c1', routeId: 'route-c', name: 'Зона C1'),
    ],
  };

  final Map<String, ArrivalInfo> arrivalsByZone = {
    'zone-a1': const ArrivalInfo(
      zoneId: 'zone-a1',
      busMinutes: [2, 8],
      trolleyMinutes: [5],
      tramMinutes: [11],
    ),
  };

  @override
  Future<ArrivalInfo> getArrivalByZone({
    required String cityId,
    required String zoneId,
  }) async {
    return arrivalsByZone[zoneId]!;
  }

  @override
  Future<List<City>> getCities() async => const [];

  @override
  Future<List<VehicleEntity>> getCityVehicles(
    String cityId, {
    List<String>? routeIds,
  }) async => const [];

  @override
  Future<List<RouteZone>> getRouteZones(String routeId) async {
    return zonesByRoute[routeId] ?? const [];
  }

  @override
  Future<List<TransportRoute>> getRoutesByType({
    required String cityId,
    required int transportType,
  }) async {
    return routesByType[transportType] ?? const [];
  }

  @override
  Future<bool> ensureCityDataFresh(String cityId) async => false;

  @override
  Future<void> preloadCityData(String cityId) async {}
}

void main() {
  group('MapOverlaysCubit', () {
    late _FakeCityRepository repository;
    late MapOverlaysCubit cubit;

    setUp(() {
      repository = _FakeCityRepository();
      cubit = MapOverlaysCubit(
        getRoutesByTypeUseCase: GetRoutesByTypeUseCase(repository),
        getRouteZonesUseCase: GetRouteZonesUseCase(repository),
        getArrivalByZoneUseCase: GetArrivalByZoneUseCase(repository),
      );
    });

    tearDown(() async {
      await cubit.close();
    });

    test('selectTransportType resets dependent state and loads routes', () async {
      await cubit.selectTransportType(cityId: 'zhytomyr', type: 0);
      await cubit.selectRoute(
        cityId: 'zhytomyr',
        route: repository.routesByType[0]!.first,
      );
      await cubit.loadArrival(cityId: 'zhytomyr', zoneId: 'zone-a1');

      await cubit.selectTransportType(cityId: 'zhytomyr', type: 1);

      expect(cubit.state.transportType, 1);
      expect(cubit.state.availableRoutes, repository.routesByType[1]);
      expect(cubit.state.selectedRoutes, isEmpty);
      expect(cubit.state.routeZones, isEmpty);
      expect(cubit.state.arrivalInfo, isNull);
      expect(cubit.state.activeRouteId, isNull);
      expect(cubit.state.activeZoneId, isNull);
    });

    test('selectRoute adds route and loads its zones', () async {
      await cubit.selectTransportType(cityId: 'zhytomyr', type: 0);

      await cubit.selectRoute(
        cityId: 'zhytomyr',
        route: repository.routesByType[0]!.first,
      );

      expect(cubit.state.selectedRoutes, [repository.routesByType[0]!.first]);
      expect(cubit.state.activeRouteId, 'route-a');
      expect(cubit.state.routeZones, repository.zonesByRoute['route-a']);
      expect(cubit.state.arrivalInfo, isNull);
    });

    test('removing active route falls back to last remaining route', () async {
      await cubit.selectTransportType(cityId: 'zhytomyr', type: 0);
      await cubit.selectRoute(
        cityId: 'zhytomyr',
        route: repository.routesByType[0]!.first,
      );
      await cubit.selectRoute(
        cityId: 'zhytomyr',
        route: repository.routesByType[0]!.last,
      );

      await cubit.removeRoute('route-b');

      expect(cubit.state.selectedRoutes, [repository.routesByType[0]!.first]);
      expect(cubit.state.activeRouteId, 'route-a');
      expect(cubit.state.routeZones, repository.zonesByRoute['route-a']);
      expect(cubit.state.arrivalInfo, isNull);
      expect(cubit.state.activeZoneId, isNull);
    });

    test('loadArrival sets active zone and arrival info', () async {
      await cubit.selectTransportType(cityId: 'zhytomyr', type: 0);
      await cubit.selectRoute(
        cityId: 'zhytomyr',
        route: repository.routesByType[0]!.first,
      );

      await cubit.loadArrival(cityId: 'zhytomyr', zoneId: 'zone-a1');

      expect(cubit.state.activeCityId, 'zhytomyr');
      expect(cubit.state.activeRouteId, 'route-a');
      expect(cubit.state.activeZoneId, 'zone-a1');
      expect(cubit.state.arrivalInfo, repository.arrivalsByZone['zone-a1']);
    });

    test('setActiveRoute switches active route without removing selection', () async {
      await cubit.selectTransportType(cityId: 'zhytomyr', type: 0);
      await cubit.selectRoute(
        cityId: 'zhytomyr',
        route: repository.routesByType[0]!.first,
      );
      await cubit.selectRoute(
        cityId: 'zhytomyr',
        route: repository.routesByType[0]!.last,
      );

      await cubit.setActiveRoute(
        cityId: 'zhytomyr',
        route: repository.routesByType[0]!.first,
      );

      expect(
        cubit.state.selectedRoutes,
        [repository.routesByType[0]!.first, repository.routesByType[0]!.last],
      );
      expect(cubit.state.activeRouteId, 'route-a');
      expect(cubit.state.routeZones, repository.zonesByRoute['route-a']);
    });

    test('selecting active route again removes it and clears dependent state', () async {
      await cubit.selectTransportType(cityId: 'zhytomyr', type: 0);
      await cubit.selectRoute(
        cityId: 'zhytomyr',
        route: repository.routesByType[0]!.first,
      );
      await cubit.loadArrival(cityId: 'zhytomyr', zoneId: 'zone-a1');

      await cubit.selectRoute(
        cityId: 'zhytomyr',
        route: repository.routesByType[0]!.first,
      );

      expect(cubit.state.selectedRoutes, isEmpty);
      expect(cubit.state.activeRouteId, isNull);
      expect(cubit.state.routeZones, isEmpty);
      expect(cubit.state.activeZoneId, isNull);
      expect(cubit.state.arrivalInfo, isNull);
    });

    test('removing inactive route keeps active route and zones intact', () async {
      await cubit.selectTransportType(cityId: 'zhytomyr', type: 0);
      await cubit.selectRoute(
        cityId: 'zhytomyr',
        route: repository.routesByType[0]!.first,
      );
      await cubit.selectRoute(
        cityId: 'zhytomyr',
        route: repository.routesByType[0]!.last,
      );

      await cubit.removeRoute('route-a');

      expect(cubit.state.selectedRoutes, [repository.routesByType[0]!.last]);
      expect(cubit.state.activeRouteId, 'route-b');
      expect(cubit.state.routeZones, repository.zonesByRoute['route-b']);
    });
  });
}
