import 'package:flutter_dozor_city/core/di/app_scope.dart';
import 'package:flutter_dozor_city/core/router/app_route_names.dart';
import 'package:flutter_dozor_city/core/router/feature_router.dart';
import 'package:flutter_dozor_city/features/city_selection/domain/usecases/check_city_data_freshness_use_case.dart';
import 'package:flutter_dozor_city/features/city_selection/domain/usecases/get_cities_use_case.dart';
import 'package:flutter_dozor_city/features/city_selection/domain/usecases/select_city_use_case.dart';
import 'package:flutter_dozor_city/features/city_selection/presentation/bloc/city_selection_cubit.dart';
import 'package:flutter_dozor_city/features/live_tracking/domain/usecases/get_city_vehicles_use_case.dart';
import 'package:flutter_dozor_city/features/live_tracking/presentation/bloc/live_tracking_cubit.dart';
import 'package:flutter_dozor_city/features/main_map/domain/usecases/check_city_data_freshness_use_case.dart';
import 'package:flutter_dozor_city/features/main_map/presentation/bloc/main_map_cubit.dart';
import 'package:flutter_dozor_city/features/main_map/presentation/bloc/map_overlays_cubit.dart';
import 'package:flutter_dozor_city/features/main_map/presentation/pages/main_map_page.dart';
import 'package:flutter_dozor_city/features/main_map/domain/usecases/get_arrival_by_zone_use_case.dart';
import 'package:flutter_dozor_city/features/main_map/domain/usecases/get_route_zones_use_case.dart';
import 'package:flutter_dozor_city/features/main_map/domain/usecases/get_routes_by_type_use_case.dart';
import 'package:flutter_dozor_city/features/route_preview/presentation/bloc/route_preview_cubit.dart';
import 'package:flutter_dozor_city/features/route_results/domain/usecases/search_routes_use_case.dart';
import 'package:flutter_dozor_city/features/route_results/domain/usecases/toggle_stored_route_use_case.dart';
import 'package:flutter_dozor_city/features/route_search/domain/usecases/load_search_draft_use_case.dart';
import 'package:flutter_dozor_city/features/route_search/domain/usecases/save_search_draft_use_case.dart';
import 'package:flutter_dozor_city/features/route_results/presentation/bloc/route_results_cubit.dart';
import 'package:flutter_dozor_city/features/route_results/presentation/pages/route_results_page.dart';
import 'package:flutter_dozor_city/features/route_search/domain/usecases/swap_search_points_use_case.dart';
import 'package:flutter_dozor_city/features/route_search/domain/usecases/toggle_transport_type_use_case.dart';
import 'package:flutter_dozor_city/features/route_search/domain/usecases/validate_route_search_use_case.dart';
import 'package:flutter_dozor_city/features/route_search/presentation/bloc/route_search_cubit.dart';
import 'package:flutter_dozor_city/features/route_search/presentation/pages/route_search_page.dart';
import 'package:flutter_dozor_city/features/stored_routes/domain/usecases/delete_stored_route_use_case.dart';
import 'package:flutter_dozor_city/features/stored_routes/domain/usecases/get_stored_routes_use_case.dart';
import 'package:flutter_dozor_city/features/stored_routes/presentation/bloc/stored_routes_cubit.dart';
import 'package:flutter_dozor_city/features/stored_routes/presentation/pages/stored_routes_page.dart';
import 'package:go_router/go_router.dart';

class MainMapRouter extends FeatureRouter {
  MainMapRouter({required AppScope scope}) : _scope = scope;

  final AppScope _scope;

  late final MainMapCubit _mainMapCubit =
      MainMapCubit(
        sessionRepository: _scope.sessionRepository,
        checkCityDataFreshnessUseCase: CheckMainMapCityDataFreshnessUseCase(
          _scope.cityRepository,
        ),
      );
  late final LiveTrackingCubit _liveTrackingCubit = LiveTrackingCubit(
    getCityVehiclesUseCase: GetCityVehiclesUseCase(_scope.cityRepository),
  );
  late final MapOverlaysCubit _overlaysCubit = MapOverlaysCubit(
    getRoutesByTypeUseCase: GetRoutesByTypeUseCase(_scope.cityRepository),
    getRouteZonesUseCase: GetRouteZonesUseCase(_scope.cityRepository),
    getArrivalByZoneUseCase: GetArrivalByZoneUseCase(_scope.cityRepository),
  );
  late final RoutePreviewCubit _routePreviewCubit = RoutePreviewCubit();

  @override
  List<RouteBase> get routes => [
        ShellRoute(
          builder: (context, state, child) => MainMapPage(
            mainMapCubit: _mainMapCubit,
            liveTrackingCubit: _liveTrackingCubit,
            overlaysCubit: _overlaysCubit,
            routePreviewCubit: _routePreviewCubit,
            mapController: _scope.mapController,
            createCitySelectionCubit: () => CitySelectionCubit(
              getCitiesUseCase: GetCitiesUseCase(_scope.cityRepository),
              selectCityUseCase: SelectCityUseCase(
                cityRepository: _scope.cityRepository,
                sessionRepository: _scope.sessionRepository,
                checkCityDataFreshnessUseCase: CheckCityDataFreshnessUseCase(
                  _scope.cityRepository,
                ),
              ),
            ),
            child: child,
          ),
          routes: [
            GoRoute(
              path: '/main-map/search',
              name: AppRouteNames.search,
              builder: (context, state) => RouteSearchPage(
                cubit: RouteSearchCubit(
                  loadSearchDraftUseCase: LoadSearchDraftUseCase(
                    _scope.searchDraftRepository,
                  ),
                  saveSearchDraftUseCase: SaveSearchDraftUseCase(
                    _scope.searchDraftRepository,
                  ),
                  toggleTransportTypeUseCase: const ToggleTransportTypeUseCase(),
                  swapSearchPointsUseCase: const SwapSearchPointsUseCase(),
                  validateRouteSearchUseCase: const ValidateRouteSearchUseCase(),
                ),
              ),
            ),
            GoRoute(
              path: '/main-map/results',
              name: AppRouteNames.results,
              builder: (context, state) => RouteResultsPage(
                cubit: RouteResultsCubit(
                  searchRoutesUseCase: SearchRoutesUseCase(
                    _scope.searchRepository,
                  ),
                  getStoredRoutesUseCase: GetStoredRoutesUseCase(
                    _scope.storedRoutesRepository,
                  ),
                  storedRoutesRepository: _scope.storedRoutesRepository,
                  toggleStoredRouteUseCase: ToggleStoredRouteUseCase(
                    _scope.storedRoutesRepository,
                  ),
                )..load(state.extra),
              ),
            ),
            GoRoute(
              path: '/main-map/stored',
              name: AppRouteNames.stored,
              builder: (context, state) => StoredRoutesPage(
                cubit: StoredRoutesCubit(
                  getStoredRoutesUseCase: GetStoredRoutesUseCase(
                    _scope.storedRoutesRepository,
                  ),
                  storedRoutesRepository: _scope.storedRoutesRepository,
                  deleteStoredRouteUseCase: DeleteStoredRouteUseCase(
                    _scope.storedRoutesRepository,
                  ),
                )..load(),
              ),
            ),
          ],
        ),
      ];
}
