import 'package:flutter_dozor_city/core/di/injector.dart';
import 'package:flutter_dozor_city/core/router/app_route_names.dart';
import 'package:flutter_dozor_city/core/router/feature_router.dart';
import 'package:flutter_dozor_city/core/domain/repositories/search_repository.dart';
import 'package:flutter_dozor_city/features/point_select/domain/usecases/get_current_location_use_case.dart';
import 'package:flutter_dozor_city/features/point_select/domain/usecases/search_address_suggestions_use_case.dart';
import 'package:flutter_dozor_city/features/point_select/presentation/bloc/point_select_cubit.dart';
import 'package:flutter_dozor_city/features/point_select/presentation/pages/point_select_page.dart';
import 'package:go_router/go_router.dart';

class PointSelectRouter extends FeatureRouter {
  const PointSelectRouter();

  @override
  List<RouteBase> get routes => [
        GoRoute(
          path: '/point-select',
          name: AppRouteNames.pointSelect,
          builder: (context, state) => PointSelectPage(
            cubit: PointSelectCubit(
              searchAddressSuggestionsUseCase: SearchAddressSuggestionsUseCase(
                injector<SearchRepository>(),
              ),
              getCurrentLocationUseCase: GetCurrentLocationUseCase(
                injector<SearchRepository>(),
              ),
            ),
          ),
        ),
      ];
}
