import 'package:flutter_dozor_city/core/di/app_scope.dart';
import 'package:flutter_dozor_city/core/router/feature_router.dart';
import 'package:flutter_dozor_city/features/city_selection/presentation/router/city_selection_router.dart';
import 'package:flutter_dozor_city/features/main_map/presentation/router/main_map_router.dart';
import 'package:flutter_dozor_city/features/point_select/presentation/router/point_select_router.dart';
import 'package:go_router/go_router.dart';

class AppRouter {
  AppRouter({required AppScope scope}) : _scope = scope {
    final routers = <FeatureRouter>[
      CitySelectionRouter(scope: scope),
      MainMapRouter(scope: scope),
      PointSelectRouter(scope: scope),
    ];
    _config = GoRouter(
      initialLocation: '/main-map/search',
      refreshListenable: _scope.sessionRepository,
      redirect: (context, state) {
        final hasCity = _scope.sessionRepository.hasSelectedCity;
        final isSelectCity = state.matchedLocation == '/select-city';

        if (!hasCity && !isSelectCity) {
          return '/select-city';
        }
        if (hasCity && isSelectCity) {
          return '/main-map/search';
        }
        return null;
      },
      routes: [
        for (final router in routers) ...router.routes,
      ],
    );
  }

  final AppScope _scope;
  late final GoRouter _config;

  GoRouter get config => _config;

  void dispose() {}
}
