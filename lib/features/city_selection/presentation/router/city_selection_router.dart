import 'package:flutter_dozor_city/di/injector.dart';
import 'package:flutter_dozor_city/core/router/app_route_names.dart';
import 'package:flutter_dozor_city/core/router/feature_router.dart';
import 'package:flutter_dozor_city/features/city_selection/presentation/bloc/city_selection_cubit.dart';
import 'package:flutter_dozor_city/features/city_selection/presentation/pages/select_city_page.dart';
import 'package:go_router/go_router.dart';

class CitySelectionRouter extends FeatureRouter {
  const CitySelectionRouter();

  @override
  List<RouteBase> get routes => [
        GoRoute(
          path: '/select-city',
          name: AppRouteNames.selectCity,
          builder: (context, state) => SelectCityPage(
            cubit: injector<CitySelectionCubit>(),
          ),
        ),
      ];
}
