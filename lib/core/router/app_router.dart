import 'package:flutter_dozor_city/core/di/injector.dart';
import 'package:flutter_dozor_city/core/domain/repositories/session_repository.dart';
import 'package:flutter_dozor_city/core/router/feature_router.dart';
import 'package:flutter_dozor_city/features/city_selection/presentation/router/city_selection_router.dart';
import 'package:flutter_dozor_city/features/main_map/presentation/router/main_map_router.dart';
import 'package:flutter_dozor_city/features/point_select/presentation/router/point_select_router.dart';
import 'package:go_router/go_router.dart';

class AppRouter {
  AppRouter() {
    final routers = <FeatureRouter>[
      const CitySelectionRouter(),
      const MainMapRouter(),
      const PointSelectRouter(),
    ];
    final sessionRepository = injector<SessionRepository>();
    _config = GoRouter(
      initialLocation: '/main-map/search',
      refreshListenable: sessionRepository,
      redirect: (context, state) {
        final hasCity = sessionRepository.hasSelectedCity;
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

  late final GoRouter _config;

  GoRouter get config => _config;

  void dispose() {}
}
