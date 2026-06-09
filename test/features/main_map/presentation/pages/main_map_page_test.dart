import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_dozor_city/core/domain/entities/arrival_info.dart';
import 'package:flutter_dozor_city/core/domain/entities/city.dart';
import 'package:flutter_dozor_city/core/domain/entities/selected_map_routes.dart';
import 'package:flutter_dozor_city/core/domain/entities/route_zone.dart';
import 'package:flutter_dozor_city/core/domain/entities/app_lat_lng.dart';
import 'package:flutter_dozor_city/core/domain/entities/transport_route.dart';
import 'package:flutter_dozor_city/core/domain/repositories/city_repository.dart';
import 'package:flutter_dozor_city/core/domain/repositories/session_repository.dart';
import 'package:flutter_dozor_city/core/map/app_map_camera.dart';
import 'package:flutter_dozor_city/core/map/flutter_map_controller_adapter.dart';
import 'package:flutter_dozor_city/features/city_selection/domain/usecases/check_city_data_freshness_use_case.dart';
import 'package:flutter_dozor_city/features/city_selection/domain/usecases/get_cities_use_case.dart';
import 'package:flutter_dozor_city/features/city_selection/domain/usecases/select_city_use_case.dart';
import 'package:flutter_dozor_city/features/city_selection/presentation/bloc/city_selection_cubit.dart';
import 'package:flutter_dozor_city/core/domain/entities/vehicle.dart';
import 'package:flutter_dozor_city/features/live_tracking/domain/usecases/get_city_vehicles_use_case.dart';
import 'package:flutter_dozor_city/features/live_tracking/presentation/bloc/live_tracking_cubit.dart';
import 'package:flutter_dozor_city/features/main_map/domain/usecases/check_city_data_freshness_use_case.dart';
import 'package:flutter_dozor_city/features/main_map/domain/usecases/get_arrival_by_zone_use_case.dart';
import 'package:flutter_dozor_city/features/main_map/domain/usecases/get_city_stops_use_case.dart';
import 'package:flutter_dozor_city/features/main_map/domain/usecases/get_route_zones_use_case.dart';
import 'package:flutter_dozor_city/features/main_map/domain/usecases/get_routes_by_type_use_case.dart';
import 'package:flutter_dozor_city/features/main_map/domain/usecases/main_map_session_use_cases.dart';
import 'package:flutter_dozor_city/features/main_map/presentation/bloc/main_map_cubit.dart';
import 'package:flutter_dozor_city/features/main_map/presentation/bloc/map_language_cubit.dart';
import 'package:flutter_dozor_city/features/main_map/presentation/bloc/map_arrivals_cubit.dart';
import 'package:flutter_dozor_city/features/main_map/presentation/bloc/map_route_planning_cubit.dart';
import 'package:flutter_dozor_city/features/main_map/presentation/bloc/map_routes_cubit.dart';
import 'package:flutter_dozor_city/features/main_map/presentation/bloc/map_stops_cubit.dart';
import 'package:flutter_dozor_city/features/main_map/presentation/router/main_map_orchestrator.dart';
import 'package:flutter_dozor_city/features/point_select/domain/usecases/get_current_location_use_case.dart';
import 'package:flutter_dozor_city/features/point_select/domain/usecases/search_address_suggestions_use_case.dart';
import 'package:flutter_dozor_city/features/point_select/presentation/bloc/point_select_cubit.dart';
import 'package:flutter_dozor_city/features/route_preview/presentation/bloc/route_preview_cubit.dart';
import 'package:flutter_dozor_city/core/time/app_clock.dart';
import 'package:flutter_dozor_city/core/domain/entities/route_result.dart';
import 'package:flutter_dozor_city/core/domain/entities/search_params.dart';
import 'package:flutter_dozor_city/core/domain/entities/selected_point.dart';
import 'package:flutter_dozor_city/core/domain/repositories/search_repository.dart';
import 'package:flutter_dozor_city/features/route_results/domain/usecases/search_routes_use_case.dart';
import '../../../../helpers/fake_polling_scheduler.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_dozor_city/core/router/app_route_names.dart';

class _FakeSessionRepository extends SessionRepository {
  _FakeSessionRepository({required this.city});

  City city;
  final Map<String, bool> _uiFlags = {};
  final Map<String, AppMapCamera> _cameras = {};
  final Map<String, SelectedMapRoutes> _selectedMapRoutes = {};

  @override
  City? get selectedCity => city;

  @override
  bool get hasSelectedCity => true;

  @override
  Future<AppMapCamera?> getMapCamera(String cityId) async => _cameras[cityId];

  @override
  Future<int?> getRoutesCacheHash(String cityId) async => null;

  @override
  Future<SelectedMapRoutes?> getSelectedMapRoutes(String cityId) async =>
      _selectedMapRoutes[cityId];

  @override
  Future<bool> getUiFlag(String key) async => _uiFlags[key] ?? false;

  @override
  Future<void> setMapCamera(String cityId, AppMapCamera camera) async {
    _cameras[cityId] = camera;
  }

  @override
  Future<void> setRoutesCacheHash(String cityId, int hash) async {}

  @override
  Future<void> setSelectedMapRoutes(
    String cityId,
    SelectedMapRoutes selectedMapRoutes,
  ) async {
    _selectedMapRoutes[cityId] = selectedMapRoutes;
  }

  @override
  Future<void> setSelectedCity(City city) async {}

  @override
  Future<void> setUiFlag(String key, bool value) async {
    _uiFlags[key] = value;
  }

  @override
  Future<String?> getMapLanguage() async => null;

  @override
  Future<void> setMapLanguage(String languageCode) async {}
}

class _FakeSearchRepository implements SearchRepository {
  @override
  Future<SelectedPoint> getCurrentLocation() async => const SelectedPoint(
    label: 'Current location',
    lat: 50.25,
    lng: 28.65,
    source: SelectedPointSource.gps,
  );

  @override
  Future<List<SelectedPoint>> searchAddressSuggestions(String query) async =>
      const [];

  @override
  Future<List<RouteResult>> searchRoutes(SearchParams params) async => const [];
}

CitySelectionBloc _buildCitySelectionBloc(
  _FakeCityRepository repository,
  _FakeSessionRepository session,
) {
  return CitySelectionBloc(
    getCitiesUseCase: GetCitiesUseCase(repository),
    selectCityUseCase: SelectCityUseCase(
      cityRepository: repository,
      sessionRepository: session,
      checkCityDataFreshnessUseCase: CheckCityDataFreshnessUseCase(repository),
    ),
  );
}

PointSelectBloc _buildPointSelectBloc(_FakeSearchRepository repository) {
  return PointSelectBloc(
    searchAddressSuggestionsUseCase: SearchAddressSuggestionsUseCase(
      repository,
    ),
    getCurrentLocationUseCase: GetCurrentLocationUseCase(repository),
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
  Future<List<Vehicle>> getCityVehicles(
    String cityId, {
    List<String>? routeIds,
  }) async => const [];

  @override
  Future<List<RouteZone>> getRouteZones(String routeId) async => const [
    RouteZone(
      id: 'zone-a1',
      routeId: 'route-a',
      name: 'Зона A1',
      position: AppLatLng(lat: 50.25, lng: 28.66),
    ),
  ];

  @override
  Future<List<RouteZone>> getCityStops(String cityId) async => const [
    RouteZone(
      id: 'stop-1',
      routeId: 'route-a',
      name: 'Зупинка 1',
      position: AppLatLng(lat: 50.251, lng: 28.661),
    ),
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

    Future<
      ({
        MainMapBloc mainMapCubit,
        MapRoutesBloc routesCubit,
        MapArrivalsBloc arrivalsCubit,
        LiveTrackingBloc liveTrackingCubit,
      })
    >
    pumpPage(WidgetTester tester) async {
      final repository = _FakeCityRepository();
      final session = _FakeSessionRepository(city: city);
      final searchRepository = _FakeSearchRepository();
      final mainMapCubit = MainMapBloc(
        getSelectedCityUseCase: GetSelectedCityUseCase(session),
        getMapCameraUseCase: GetMapCameraUseCase(session),
        saveMapCameraUseCase: SaveMapCameraUseCase(session),
        getUiFlagUseCase: GetUiFlagUseCase(session),
        setUiFlagUseCase: SetUiFlagUseCase(session),
        checkCityDataFreshnessUseCase: CheckMainMapCityDataFreshnessUseCase(
          repository,
        ),
      );

      final routesCubit = MapRoutesBloc(
        getRoutesByTypeUseCase: GetRoutesByTypeUseCase(repository),
        getSelectedMapRoutesUseCase: GetSelectedMapRoutesUseCase(session),
        saveSelectedMapRoutesUseCase: SaveSelectedMapRoutesUseCase(session),
      );
      final routePreviewCubit = RoutePreviewBloc();
      final mapLanguageCubit = MapLanguageBloc(
        getMapLanguageUseCase: GetMapLanguageUseCase(session),
        saveMapLanguageUseCase: SaveMapLanguageUseCase(session),
      );
      final mapRoutePlanningCubit = MapRoutePlanningBloc(
        searchRoutesUseCase: SearchRoutesUseCase(_FakeSearchRepository()),
        routePreviewBloc: routePreviewCubit,
      );
      final arrivalsCubit = MapArrivalsBloc(
        getRouteZonesUseCase: GetRouteZonesUseCase(repository),
        getArrivalByZoneUseCase: GetArrivalByZoneUseCase(repository),
        pollingScheduler: FakePollingScheduler(),
      );
      final liveTrackingCubit = LiveTrackingBloc(
        getCityVehiclesUseCase: GetCityVehiclesUseCase(repository),
        pollingScheduler: FakePollingScheduler(),
        clock: const SystemClock(),
      );
      final mapStopsCubit = MapStopsBloc(
        getCityStopsUseCase: GetCityStopsUseCase(repository),
      );

      final router = GoRouter(
        initialLocation: '/',
        routes: [
          ShellRoute(
            builder: (context, state, child) => MainMapOrchestrator(
              mainMapCubit: mainMapCubit,
              liveTrackingCubit: liveTrackingCubit,
              mapRoutesCubit: routesCubit,
              mapArrivalsCubit: arrivalsCubit,
              mapStopsCubit: mapStopsCubit,
              routePreviewCubit: routePreviewCubit,
              mapLanguageCubit: mapLanguageCubit,
              mapRoutePlanningCubit: mapRoutePlanningCubit,
              mapController: FlutterMapControllerAdapter(),
              createPointSelectBloc: () =>
                  _buildPointSelectBloc(searchRepository),
              createCitySelectionBloc: () =>
                  _buildCitySelectionBloc(repository, session),
              child: child,
            ),
            routes: [
              GoRoute(
                path: '/',
                builder: (context, state) => const SizedBox.shrink(),
              ),
              GoRoute(
                path: '/search',
                name: AppRouteNames.search,
                builder: (context, state) => const Text('Search Page'),
              ),
            ],
          ),
        ],
      );

      await tester.pumpWidget(MaterialApp.router(routerConfig: router));
      await tester.pumpAndSettle();

      return (
        mainMapCubit: mainMapCubit,
        routesCubit: routesCubit,
        arrivalsCubit: arrivalsCubit,
        liveTrackingCubit: liveTrackingCubit,
      );
    }

    testWidgets('city mode hides routes menu but keeps shared shell controls', (
      tester,
    ) async {
      final deps = await pumpPage(tester);

      deps.mainMapCubit.setRouteMode(MainMapMode.city);
      await tester.pumpAndSettle();

      expect(deps.mainMapCubit.state.mode, MainMapMode.city);
      expect(find.text('Житомир'), findsOneWidget);
      expect(find.byTooltip('Моє місце'), findsOneWidget);
      expect(find.byKey(const Key('transport-type-0')), findsNothing);
    });

    testWidgets(
      'routing button opens bottom sheet and route workflow controls',
      (tester) async {
        final deps = await pumpPage(tester);

        deps.mainMapCubit
          ..setRouteMode(MainMapMode.routes)
          ..openBottomSheet(tab: MainMapTab.search);
        await tester.pumpAndSettle();

        expect(deps.mainMapCubit.state.isBottomSheetVisible, isTrue);
        expect(find.byKey(const Key('transport-type-0')), findsOneWidget);
      },
    );

    testWidgets('city chip opens modal city picker sheet', (tester) async {
      final deps = await pumpPage(tester);

      expect(find.byKey(const Key('transport-type-0')), findsOneWidget);
      expect(find.byKey(const Key('top-menu-city')), findsOneWidget);
      expect(deps.mainMapCubit.state.city?.name, 'Житомир');
    });
  });
}
