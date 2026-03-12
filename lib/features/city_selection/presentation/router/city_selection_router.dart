import 'package:flutter_dozor_city/core/di/injector.dart';
import 'package:flutter_dozor_city/core/router/app_route_names.dart';
import 'package:flutter_dozor_city/core/router/feature_router.dart';
import 'package:flutter_dozor_city/core/domain/repositories/city_repository.dart';
import 'package:flutter_dozor_city/core/domain/repositories/session_repository.dart';
import 'package:flutter_dozor_city/features/city_selection/domain/usecases/check_city_data_freshness_use_case.dart';
import 'package:flutter_dozor_city/features/city_selection/domain/usecases/get_cities_use_case.dart';
import 'package:flutter_dozor_city/features/city_selection/domain/usecases/select_city_use_case.dart';
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
            cubit: CitySelectionCubit(
              getCitiesUseCase: GetCitiesUseCase(injector<CityRepository>()),
              selectCityUseCase: SelectCityUseCase(
                cityRepository: injector<CityRepository>(),
                sessionRepository: injector<SessionRepository>(),
                checkCityDataFreshnessUseCase: CheckCityDataFreshnessUseCase(
                  injector<CityRepository>(),
                ),
              ),
            ),
          ),
        ),
      ];
}
