import 'package:flutter_dozor_city/features/route_search/data/models/json_route_result_model.dart';
import 'package:flutter_dozor_city/core/domain/entities/route_result.dart';

class SearchRouteResultMapper {
  const SearchRouteResultMapper();

  RouteResult map({
    required RouteResultSearchDto model,
    required int index,
  }) {
    return model.toEntity(
      id: 'search-$index',
      title: _buildTitle(model),
    );
  }

  String _buildTitle(RouteResultSearchDto model) {
    return model.transferRoutesIds.isEmpty
        ? 'Прямий маршрут'
        : 'Маршрут з пересадкою';
  }
}
