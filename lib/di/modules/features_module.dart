import 'package:flutter_dozor_city/di/injector.dart';
import 'package:flutter_dozor_city/core/domain/repositories/city_repository.dart';
import 'package:flutter_dozor_city/core/domain/repositories/search_draft_repository.dart';
import 'package:flutter_dozor_city/core/domain/repositories/search_repository.dart';
import 'package:flutter_dozor_city/core/domain/repositories/session_repository.dart';
import 'package:flutter_dozor_city/core/domain/repositories/stored_routes_repository.dart';
import 'package:flutter_dozor_city/core/time/app_clock.dart';
import 'package:flutter_dozor_city/core/time/polling_scheduler.dart';

// City Selection
import 'package:flutter_dozor_city/features/city_selection/domain/usecases/check_city_data_freshness_use_case.dart'
    as city_selection;
import 'package:flutter_dozor_city/features/city_selection/domain/usecases/get_cities_use_case.dart';
import 'package:flutter_dozor_city/features/city_selection/domain/usecases/select_city_use_case.dart';
import 'package:flutter_dozor_city/features/city_selection/presentation/bloc/city_selection_cubit.dart';

// Live Tracking
import 'package:flutter_dozor_city/features/live_tracking/domain/usecases/get_city_vehicles_use_case.dart';
import 'package:flutter_dozor_city/features/live_tracking/presentation/bloc/live_tracking_cubit.dart';

// Main Map
import 'package:flutter_dozor_city/features/main_map/domain/usecases/check_city_data_freshness_use_case.dart';
import 'package:flutter_dozor_city/features/main_map/domain/usecases/get_city_stops_use_case.dart';
import 'package:flutter_dozor_city/features/main_map/domain/usecases/get_arrival_by_zone_use_case.dart';
import 'package:flutter_dozor_city/features/main_map/domain/usecases/get_route_zones_use_case.dart';
import 'package:flutter_dozor_city/features/main_map/domain/usecases/get_routes_by_type_use_case.dart';
import 'package:flutter_dozor_city/features/main_map/domain/usecases/main_map_session_use_cases.dart';
import 'package:flutter_dozor_city/features/main_map/presentation/bloc/main_map_cubit.dart';
import 'package:flutter_dozor_city/features/main_map/presentation/bloc/map_language_cubit.dart';
import 'package:flutter_dozor_city/features/main_map/presentation/bloc/map_route_planning_cubit.dart';
import 'package:flutter_dozor_city/features/main_map/presentation/bloc/map_overlays_cubit.dart';
import 'package:flutter_dozor_city/features/main_map/presentation/bloc/map_routes_cubit.dart';
import 'package:flutter_dozor_city/features/main_map/presentation/bloc/map_arrivals_cubit.dart';
import 'package:flutter_dozor_city/features/main_map/presentation/bloc/map_stops_cubit.dart';

// Point Select
import 'package:flutter_dozor_city/features/point_select/domain/usecases/get_current_location_use_case.dart';
import 'package:flutter_dozor_city/features/point_select/domain/usecases/search_address_suggestions_use_case.dart';
import 'package:flutter_dozor_city/features/point_select/presentation/bloc/point_select_cubit.dart';

// Route Preview
import 'package:flutter_dozor_city/features/route_preview/presentation/bloc/route_preview_cubit.dart';

// Route Results
import 'package:flutter_dozor_city/features/route_results/domain/usecases/search_routes_use_case.dart';
import 'package:flutter_dozor_city/features/route_results/domain/usecases/toggle_stored_route_use_case.dart';
import 'package:flutter_dozor_city/features/route_results/presentation/bloc/route_results_cubit.dart';

// Route Search
import 'package:flutter_dozor_city/features/route_search/domain/usecases/load_search_draft_use_case.dart';
import 'package:flutter_dozor_city/features/route_search/domain/usecases/save_search_draft_use_case.dart';
import 'package:flutter_dozor_city/features/route_search/domain/usecases/swap_search_points_use_case.dart';
import 'package:flutter_dozor_city/features/route_search/domain/usecases/toggle_transport_type_use_case.dart';
import 'package:flutter_dozor_city/features/route_search/domain/usecases/validate_route_search_use_case.dart';
import 'package:flutter_dozor_city/features/route_search/presentation/bloc/route_search_cubit.dart';

// Stored Routes
import 'package:flutter_dozor_city/features/stored_routes/domain/usecases/delete_stored_route_use_case.dart';
import 'package:flutter_dozor_city/features/stored_routes/domain/usecases/get_stored_routes_use_case.dart';
import 'package:flutter_dozor_city/features/stored_routes/domain/usecases/watch_stored_routes_use_case.dart';
import 'package:flutter_dozor_city/features/stored_routes/presentation/bloc/stored_routes_cubit.dart';

abstract final class FeaturesModule {
  static void register() {
    // City Selection
    injector.registerFactory(
      () => GetCitiesUseCase(injector<CityRepository>()),
    );
    injector.registerFactory(
      () => city_selection.CheckCityDataFreshnessUseCase(
        injector<CityRepository>(),
      ),
    );
    injector.registerFactory(
      () => SelectCityUseCase(
        cityRepository: injector<CityRepository>(),
        sessionRepository: injector<SessionRepository>(),
        checkCityDataFreshnessUseCase:
            injector<city_selection.CheckCityDataFreshnessUseCase>(),
      ),
    );
    injector.registerFactory(
      () => CitySelectionCubit(
        getCitiesUseCase: injector(),
        selectCityUseCase: injector(),
      ),
    );

    // Live Tracking
    injector.registerFactory(
      () => GetCityVehiclesUseCase(injector<CityRepository>()),
    );
    injector.registerFactory(
      () => LiveTrackingCubit(
        getCityVehiclesUseCase: injector(),
        pollingScheduler: injector<PollingScheduler>(),
        clock: injector<AppClock>(),
      ),
    );

    // Main Map
    injector.registerFactory(
      () => GetSelectedCityUseCase(injector<SessionRepository>()),
    );
    injector.registerFactory(
      () => GetMapCameraUseCase(injector<SessionRepository>()),
    );
    injector.registerFactory(
      () => SaveMapCameraUseCase(injector<SessionRepository>()),
    );
    injector.registerFactory(
      () => GetUiFlagUseCase(injector<SessionRepository>()),
    );
    injector.registerFactory(
      () => SetUiFlagUseCase(injector<SessionRepository>()),
    );
    injector.registerFactory(
      () => GetSelectedMapRoutesUseCase(injector<SessionRepository>()),
    );
    injector.registerFactory(
      () => SaveSelectedMapRoutesUseCase(injector<SessionRepository>()),
    );
    injector.registerFactory(
      () => GetMapLanguageUseCase(injector<SessionRepository>()),
    );
    injector.registerFactory(
      () => SaveMapLanguageUseCase(injector<SessionRepository>()),
    );
    injector.registerFactory(
      () => CheckMainMapCityDataFreshnessUseCase(injector<CityRepository>()),
    );

    injector.registerFactory(
      () => MainMapCubit(
        getSelectedCityUseCase: injector(),
        getMapCameraUseCase: injector(),
        saveMapCameraUseCase: injector(),
        getUiFlagUseCase: injector(),
        setUiFlagUseCase: injector(),
        checkCityDataFreshnessUseCase: injector(),
      ),
    );

    // Map Routes & Arrivals
    injector.registerFactory(
      () => GetRoutesByTypeUseCase(injector<CityRepository>()),
    );
    injector.registerFactory(
      () => GetRouteZonesUseCase(injector<CityRepository>()),
    );
    injector.registerFactory(
      () => GetCityStopsUseCase(injector<CityRepository>()),
    );
    injector.registerFactory(
      () => GetArrivalByZoneUseCase(injector<CityRepository>()),
    );

    injector.registerFactory(
      () => MapRoutesCubit(
        getRoutesByTypeUseCase: injector(),
        getSelectedMapRoutesUseCase: injector(),
        saveSelectedMapRoutesUseCase: injector(),
      ),
    );
    injector.registerFactory(
      () => MapLanguageCubit(
        getMapLanguageUseCase: injector(),
        saveMapLanguageUseCase: injector(),
      ),
    );

    injector.registerFactory(
      () => MapArrivalsCubit(
        getRouteZonesUseCase: injector(),
        getArrivalByZoneUseCase: injector(),
        pollingScheduler: injector<PollingScheduler>(),
      ),
    );
    injector.registerFactory(
      () => MapStopsCubit(
        getCityStopsUseCase: injector(),
      ),
    );

    injector.registerFactory(
      () => MapOverlaysCubit(
        getRoutesByTypeUseCase: injector(),
        getRouteZonesUseCase: injector(),
        getArrivalByZoneUseCase: injector(),
        pollingScheduler: injector<PollingScheduler>(),
      ),
    );

    // Point Select
    injector.registerFactory(
      () => GetCurrentLocationUseCase(injector<SearchRepository>()),
    );
    injector.registerFactory(
      () => SearchAddressSuggestionsUseCase(injector<SearchRepository>()),
    );
    injector.registerFactory(
      () => PointSelectCubit(
        getCurrentLocationUseCase: injector(),
        searchAddressSuggestionsUseCase: injector(),
      ),
    );

    // Route Preview
    injector.registerSingleton<RoutePreviewCubit>(RoutePreviewCubit());
    injector.registerFactory(
      () => MapRoutePlanningCubit(
        searchRoutesUseCase: injector(),
        routePreviewCubit: injector<RoutePreviewCubit>(),
      ),
    );

    // Route Results
    injector.registerFactory(
      () => SearchRoutesUseCase(injector<SearchRepository>()),
    );
    injector.registerFactory(
      () => RouteResultsCubit(
        searchRoutesUseCase: injector(),
        getStoredRoutesUseCase: injector(),
        watchStoredRoutesUseCase: injector(),
        toggleStoredRouteUseCase: injector(),
      ),
    );

    // Route Search
    injector.registerFactory(
      () => LoadSearchDraftUseCase(injector<SearchDraftRepository>()),
    );
    injector.registerFactory(
      () => SaveSearchDraftUseCase(injector<SearchDraftRepository>()),
    );
    injector.registerFactory(() => const ToggleTransportTypeUseCase());
    injector.registerFactory(() => const SwapSearchPointsUseCase());
    injector.registerFactory(() => const ValidateRouteSearchUseCase());
    injector.registerFactory(
      () => RouteSearchCubit(
        loadSearchDraftUseCase: injector(),
        saveSearchDraftUseCase: injector(),
        toggleTransportTypeUseCase: injector(),
        swapSearchPointsUseCase: injector(),
        validateRouteSearchUseCase: injector(),
      ),
    );

    // Stored Routes
    injector.registerFactory(
      () => GetStoredRoutesUseCase(injector<StoredRoutesRepository>()),
    );
    injector.registerFactory(
      () => WatchStoredRoutesUseCase(injector<StoredRoutesRepository>()),
    );
    injector.registerFactory(
      () => DeleteStoredRouteUseCase(injector<StoredRoutesRepository>()),
    );
    injector.registerFactory(
      () => ToggleStoredRouteUseCase(injector<StoredRoutesRepository>()),
    );
    injector.registerFactory(
      () => StoredRoutesCubit(
        getStoredRoutesUseCase: injector(),
        watchStoredRoutesUseCase: injector(),
        deleteStoredRouteUseCase: injector(),
      ),
    );
  }
}
