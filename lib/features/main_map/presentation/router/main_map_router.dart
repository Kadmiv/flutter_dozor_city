import 'package:flutter_dozor_city/di/injector.dart';
import 'package:flutter_dozor_city/core/router/app_route_names.dart';
import 'package:flutter_dozor_city/core/router/feature_router.dart';
import 'package:flutter_dozor_city/core/map/map_controller.dart';
import 'package:flutter_dozor_city/features/city_selection/presentation/bloc/city_selection_cubit.dart';
import 'package:flutter_dozor_city/features/live_tracking/presentation/bloc/live_tracking_cubit.dart';
import 'package:flutter_dozor_city/features/main_map/presentation/bloc/main_map_cubit.dart';
import 'package:flutter_dozor_city/features/main_map/presentation/bloc/map_overlays_cubit.dart';

import 'package:flutter_dozor_city/features/main_map/presentation/bloc/map_routes_cubit.dart';
import 'package:flutter_dozor_city/features/main_map/presentation/bloc/map_arrivals_cubit.dart';
import 'package:flutter_dozor_city/features/main_map/presentation/router/main_map_orchestrator.dart';
import 'package:flutter_dozor_city/features/point_select/presentation/bloc/point_select_cubit.dart';
import 'package:flutter_dozor_city/features/route_preview/presentation/bloc/route_preview_cubit.dart';
import 'package:flutter_dozor_city/features/route_results/presentation/bloc/route_results_cubit.dart';
import 'package:flutter_dozor_city/features/route_results/presentation/pages/route_results_page.dart';
import 'package:flutter_dozor_city/features/route_search/presentation/bloc/route_search_cubit.dart';
import 'package:flutter_dozor_city/features/route_search/presentation/pages/route_search_page.dart';
import 'package:flutter_dozor_city/core/router/route_args.dart';
import 'package:flutter_dozor_city/features/stored_routes/presentation/bloc/stored_routes_cubit.dart';
import 'package:flutter_dozor_city/features/stored_routes/presentation/pages/stored_routes_page.dart';
import 'package:go_router/go_router.dart';

class MainMapRouter extends FeatureRouter {
  const MainMapRouter();

  MainMapCubit get _mainMapCubit => injector<MainMapCubit>();

  LiveTrackingCubit get _liveTrackingCubit => injector<LiveTrackingCubit>();

  MapRoutesCubit get _mapRoutesCubit => injector<MapRoutesCubit>();

  MapArrivalsCubit get _mapArrivalsCubit => injector<MapArrivalsCubit>();

  RoutePreviewCubit get _routePreviewCubit => injector<RoutePreviewCubit>();

  @override
  List<RouteBase> get routes => [
        ShellRoute(
          builder: (context, state, child) => MainMapOrchestrator(
            mainMapCubit: _mainMapCubit,
            liveTrackingCubit: _liveTrackingCubit,
            mapOverlaysCubit: injector<MapOverlaysCubit>(),
            mapRoutesCubit: _mapRoutesCubit,
            mapArrivalsCubit: _mapArrivalsCubit,
            routePreviewCubit: _routePreviewCubit,
            mapController: injector<MapController>(),
            createCitySelectionCubit: () => injector<CitySelectionCubit>(),
            child: child,
          ),
          routes: [
            GoRoute(
              path: '/main-map/search',
              name: AppRouteNames.search,
              builder: (context, state) => RouteSearchPage(
                cubit: injector<RouteSearchCubit>(),
                createPointSelectCubit: () => injector<PointSelectCubit>(),
              ),
            ),
            GoRoute(
              path: '/main-map/results',
              name: AppRouteNames.results,
              builder: (context, state) {
                final args = state.extra as RouteResultsArgs?;
                return RouteResultsPage(
                  cubit: injector<RouteResultsCubit>()..load(args?.params),
                );
              },
            ),
            GoRoute(
              path: '/main-map/stored',
              name: AppRouteNames.stored,
              builder: (context, state) => StoredRoutesPage(
                cubit: injector<StoredRoutesCubit>(),
              ),
            ),
          ],
        ),
      ];
}
