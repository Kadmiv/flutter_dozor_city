import 'package:flutter_dozor_city/core/data/models/json_route_result_model.dart';
import 'package:flutter_dozor_city/core/domain/entities/route_result.dart';

class SearchRouteResultMapper {
  const SearchRouteResultMapper();

  RouteResult map({
    required JsonRouteResultModel model,
    required int index,
  }) {
    return model.toEntity(
      id: 'search-$index',
      title: _buildTitle(model),
    );
  }

  String _buildTitle(JsonRouteResultModel model) {
    return model.transferRoutesIds.isEmpty
        ? 'Прямий маршрут'
        : 'Маршрут з пересадкою';
  }
}
