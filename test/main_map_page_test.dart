import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_dozor_city/core/domain/entities/arrival_info.dart';
import 'package:flutter_dozor_city/core/domain/entities/city.dart';
import 'package:flutter_dozor_city/core/domain/entities/route_zone.dart';
import 'package:flutter_dozor_city/core/domain/entities/transport_route.dart';
import 'package:flutter_dozor_city/core/domain/repositories/city_repository.dart';
import 'package:flutter_dozor_city/core/domain/repositories/session_repository.dart';
import 'package:flutter_dozor_city/core/map/app_map_camera.dart';
import 'package:flutter_dozor_city/core/map/flutter_map_controller_adapter.dart';
import 'package:flutter_dozor_city/features/city_selection/domain/usecases/check_city_data_freshness_use_case.dart';
import 'package:flutter_dozor_city/features/city_selection/domain/usecases/get_cities_use_case.dart';
import 'package:flutter_dozor_city/features/city_selection/domain/usecases/select_city_use_case.dart';
import 'package:flutter_dozor_city/features/city_selection/presentation/bloc/city_selection_cubit.dart';
import 'package:flutter_dozor_city/features/live_tracking/domain/entities/vehicle_entity.dart';
import 'package:flutter_dozor_city/features/live_tracking/domain/usecases/get_city_vehicles_use_case.dart';
import 'package:flutter_dozor_city/features/live_tracking/presentation/bloc/live_tracking_cubit.dart';
import 'package:flutter_dozor_city/features/main_map/domain/usecases/check_city_data_freshness_use_case.dart';
import 'package:flutter_dozor_city/features/main_map/domain/usecases/get_arrival_by_zone_use_case.dart';
import 'package:flutter_dozor_city/features/main_map/domain/usecases/get_route_zones_use_case.dart';
import 'package:flutter_dozor_city/features/main_map/domain/usecases/get_routes_by_type_use_case.dart';
import 'package:flutter_dozor_city/features/main_map/presentation/bloc/main_map_cubit.dart';
import 'package:flutter_dozor_city/features/main_map/presentation/bloc/map_overlays_cubit.dart';
import 'package:flutter_dozor_city/features/main_map/presentation/pages/main_map_page.dart';
import 'package:flutter_dozor_city/features/route_preview/presentation/bloc/route_preview_cubit.dart';

class _FakeSessionRepository extends SessionRepository {
  _FakeSessionRepository({required this.city});

  City city;
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

CitySelectionCubit _buildCitySelectionCubit(
  _FakeCityRepository repository,
  _FakeSessionRepository session,
) {
  return CitySelectionCubit(
    getCitiesUseCase: GetCitiesUseCase(repository),
    selectCityUseCase: SelectCityUseCase(
      cityRepository: repository,
      sessionRepository: session,
      checkCityDataFreshnessUseCase: CheckCityDataFreshnessUseCase(repository),
    ),
  );
}

class _FakeCityRepository implements CityRepository {
  @override
  Future<bool> ensureCityDataFresh(String cityId) async => true;

  @override
  Future<ArrivalInfo> getArrivalByZone({
    required String cityId,
    required String zoneId,
  }) async {
    return const ArrivalInfo(
      zoneId: 'zone-a1',
      busMinutes: [2],
      trolleyMinutes: [5],
      tramMinutes: [9],
    );
  }

  @override
  Future<List<City>> getCities() async => const [
        City(
          id: 'zhytomyr',
          name: 'Житомир',
          region: 'Житомирська область',
          centerLat: 50.25465,
          centerLng: 28.65867,
          zoom: 12.5,
        ),
      ];

  @override
  Future<List<VehicleEntity>> getCityVehicles(
    String cityId, {
    List<String>? routeIds,
  }) async => const [];

  @override
  Future<List<RouteZone>> getRouteZones(String routeId) async => const [
        RouteZone(id: 'zone-a1', routeId: 'route-a', name: 'Зона A1'),
      ];

  @override
  Future<List<TransportRoute>> getRoutesByType({
    required String cityId,
    required int transportType,
  }) async => const [
        TransportRoute(
          id: 'route-a',
          shortName: '1A',
          title: 'Маршрут 1A',
          transportType: 0,
        ),
      ];

  @override
  Future<void> preloadCityData(String cityId) async {}
}

void main() {
  group('MainMapPage shell', () {
    const city = City(
      id: 'zhytomyr',
      name: 'Житомир',
      region: 'Житомирська область',
      centerLat: 50.25465,
      centerLng: 28.65867,
      zoom: 12.5,
    );

    Future<({
      MainMapCubit mainMapCubit,
      MapOverlaysCubit overlaysCubit,
      LiveTrackingCubit liveTrackingCubit,
    })> pumpPage(WidgetTester tester) async {
      final repository = _FakeCityRepository();
      final session = _FakeSessionRepository(city: city);
      final mainMapCubit = MainMapCubit(
        sessionRepository: session,
        checkCityDataFreshnessUseCase:
            CheckMainMapCityDataFreshnessUseCase(repository),
      );
      final overlaysCubit = MapOverlaysCubit(
        getRoutesByTypeUseCase: GetRoutesByTypeUseCase(repository),
        getRouteZonesUseCase: GetRouteZonesUseCase(repository),
        getArrivalByZoneUseCase: GetArrivalByZoneUseCase(repository),
      );
      final liveTrackingCubit = LiveTrackingCubit(
        getCityVehiclesUseCase: GetCityVehiclesUseCase(repository),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: MainMapPage(
            mainMapCubit: mainMapCubit,
            liveTrackingCubit: liveTrackingCubit,
              overlaysCubit: overlaysCubit,
              routePreviewCubit: RoutePreviewCubit(),
              mapController: FlutterMapControllerAdapter(),
              createCitySelectionCubit: () =>
                  _buildCitySelectionCubit(repository, session),
              child: const Text('Shell child'),
            ),
          ),
      );
      await tester.pumpAndSettle();

      return (
        mainMapCubit: mainMapCubit,
        overlaysCubit: overlaysCubit,
        liveTrackingCubit: liveTrackingCubit,
      );
    }

    testWidgets('city mode hides routes menu but keeps shared shell controls',
        (tester) async {
      final deps = await pumpPage(tester);

      deps.mainMapCubit.setRouteMode(MainMapMode.city);
      await tester.pumpAndSettle();

      expect(deps.mainMapCubit.state.mode, MainMapMode.city);
      expect(find.text('Житомир'), findsOneWidget);
      expect(find.text('Shell child'), findsNothing);
      expect(find.text('Маркери'), findsOneWidget);
      expect(find.text('Пошук'), findsNothing);
      expect(find.byTooltip('Моє місце'), findsOneWidget);
      expect(find.byKey(const Key('transport-type-0')), findsNothing);
    });

    testWidgets('routing button opens bottom sheet and route workflow controls',
        (tester) async {
      final deps = await pumpPage(tester);

      deps.mainMapCubit.setRouteMode(MainMapMode.routes);
      await tester.tap(find.text('Маршрути'));
      await tester.pumpAndSettle();

      expect(deps.mainMapCubit.state.isBottomSheetVisible, isTrue);
      expect(find.text('Пошук'), findsOneWidget);
      expect(find.byKey(const Key('transport-type-0')), findsOneWidget);
      expect(find.text('Маркери'), findsOneWidget);
      expect(find.byTooltip('Маршрути'), findsOneWidget);
    });

    testWidgets('city chip opens modal city picker sheet', (tester) async {
      await pumpPage(tester);

      await tester.tap(find.text('Житомир'));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('city-picker-sheet')), findsOneWidget);
      expect(find.text('Житомирська область'), findsWidgets);
    });
  });
}
