import 'package:flutter_dozor_city/core/domain/entities/route_result.dart';
import 'package:flutter_dozor_city/core/domain/entities/search_params.dart';
import 'package:flutter_dozor_city/core/domain/entities/selected_point.dart';

abstract class SearchRepository {
  Future<List<SelectedPoint>> searchAddressSuggestions(String query);
  Future<SelectedPoint> getCurrentLocation();
  Future<List<RouteResult>> searchRoutes(SearchParams params);
}
