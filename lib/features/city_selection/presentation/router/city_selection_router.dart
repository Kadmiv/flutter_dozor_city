import 'package:flutter_dozor_city/core/di/app_scope.dart';
import 'package:flutter_dozor_city/core/router/app_route_names.dart';
import 'package:flutter_dozor_city/core/router/feature_router.dart';
import 'package:flutter_dozor_city/features/city_selection/domain/usecases/check_city_data_freshness_use_case.dart';
import 'package:flutter_dozor_city/features/city_selection/domain/usecases/get_cities_use_case.dart';
import 'package:flutter_dozor_city/features/city_selection/domain/usecases/select_city_use_case.dart';
import 'package:flutter_dozor_city/features/city_selection/presentation/bloc/city_selection_cubit.dart';
import 'package:flutter_dozor_city/features/city_selection/presentation/pages/select_city_page.dart';
import 'package:go_router/go_router.dart';

class CitySelectionRouter extends FeatureRouter {
  CitySelectionRouter({required AppScope scope}) : _scope = scope;

  final AppScope _scope;

  @override
  List<RouteBase> get routes => [
        GoRoute(
          path: '/select-city',
          name: AppRouteNames.selectCity,
          builder: (context, state) => SelectCityPage(
            cubit: CitySelectionCubit(
              getCitiesUseCase: GetCitiesUseCase(_scope.cityRepository),
              selectCityUseCase: SelectCityUseCase(
                cityRepository: _scope.cityRepository,
                sessionRepository: _scope.sessionRepository,
                checkCityDataFreshnessUseCase: CheckCityDataFreshnessUseCase(
                  _scope.cityRepository,
                ),
              ),
            ),
          ),
        ),
      ];
}
