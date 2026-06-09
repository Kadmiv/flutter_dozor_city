import 'package:flutter_dozor_city/di/injector.dart';
import 'package:flutter_dozor_city/core/router/app_route_names.dart';
import 'package:flutter_dozor_city/core/router/feature_router.dart';
import 'package:flutter_dozor_city/core/map/map_controller.dart';
import 'package:flutter_dozor_city/features/city_selection/presentation/bloc/city_selection_cubit.dart';
import 'package:flutter_dozor_city/features/live_tracking/presentation/bloc/live_tracking_cubit.dart';
import 'package:flutter_dozor_city/features/main_map/presentation/bloc/main_map_cubit.dart';
import 'package:flutter_dozor_city/features/main_map/presentation/bloc/map_language_cubit.dart';
import 'package:flutter_dozor_city/features/main_map/presentation/bloc/map_route_planning_cubit.dart';
import 'package:flutter_dozor_city/features/main_map/presentation/bloc/map_routes_cubit.dart';
import 'package:flutter_dozor_city/features/main_map/presentation/bloc/map_arrivals_cubit.dart';
import 'package:flutter_dozor_city/features/main_map/presentation/bloc/map_stops_cubit.dart';
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

  MainMapBloc get _mainMapCubit => injector<MainMapBloc>();

  LiveTrackingBloc get _liveTrackingCubit => injector<LiveTrackingBloc>();

  MapRoutesBloc get _mapRoutesCubit => injector<MapRoutesBloc>();

  MapArrivalsBloc get _mapArrivalsCubit => injector<MapArrivalsBloc>();

  MapStopsBloc get _mapStopsCubit => injector<MapStopsBloc>();

  RoutePreviewBloc get _routePreviewCubit => injector<RoutePreviewBloc>();

  MapLanguageBloc get _mapLanguageCubit => injector<MapLanguageBloc>();

  MapRoutePlanningBloc get _mapRoutePlanningCubit =>
      injector<MapRoutePlanningBloc>();

  @override
  List<RouteBase> get routes => [
    ShellRoute(
      builder: (context, state, child) => MainMapOrchestrator(
        mainMapCubit: _mainMapCubit,
        liveTrackingCubit: _liveTrackingCubit,
        mapRoutesCubit: _mapRoutesCubit,
        mapArrivalsCubit: _mapArrivalsCubit,
        mapStopsCubit: _mapStopsCubit,
        routePreviewCubit: _routePreviewCubit,
        mapLanguageCubit: _mapLanguageCubit,
        mapRoutePlanningCubit: _mapRoutePlanningCubit,
        mapController: injector<MapController>(),
        createPointSelectBloc: () => injector<PointSelectBloc>(),
        createCitySelectionBloc: () => injector<CitySelectionBloc>(),
        child: child,
      ),
      routes: [
        GoRoute(
          path: '/main-map/search',
          name: AppRouteNames.search,
          builder: (context, state) => RouteSearchPage(
            cubit: injector<RouteSearchBloc>(),
            createPointSelectBloc: () => injector<PointSelectBloc>(),
          ),
        ),
        GoRoute(
          path: '/main-map/results',
          name: AppRouteNames.results,
          builder: (context, state) {
            final args = state.extra as RouteResultsArgs?;
            return RouteResultsPage(
              cubit: injector<RouteResultsBloc>()..load(args?.params),
            );
          },
        ),
        GoRoute(
          path: '/main-map/stored',
          name: AppRouteNames.stored,
          builder: (context, state) =>
              StoredRoutesPage(cubit: injector<StoredRoutesBloc>()),
        ),
      ],
    ),
  ];
}
