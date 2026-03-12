import 'package:flutter_dozor_city/core/domain/entities/search_params.dart';
import 'package:flutter_dozor_city/core/domain/entities/selected_point.dart';

class RouteSearchValidationResult {
  const RouteSearchValidationResult({
    required this.errorText,
    required this.params,
  });

  final String? errorText;
  final SearchParams? params;
}

class ValidateRouteSearchUseCase {
  const ValidateRouteSearchUseCase();

  RouteSearchValidationResult call({
    required SelectedPoint? start,
    required SelectedPoint? end,
    required Set<int> transportTypes,
  }) {
    if (start == null || end == null) {
      return const RouteSearchValidationResult(
        errorText: 'Заповніть точки Від та До',
        params: null,
      );
    }
    if (transportTypes.isEmpty) {
      return const RouteSearchValidationResult(
        errorText: 'Оберіть хоча б один тип транспорту',
        params: null,
      );
    }
    if (start == end) {
      return const RouteSearchValidationResult(
        errorText: 'Початок і кінець маршруту співпадають',
        params: null,
      );
    }
    return RouteSearchValidationResult(
      errorText: null,
      params: SearchParams(
        start: start,
        end: end,
        transportTypes: transportTypes,
      ),
    );
  }
}
