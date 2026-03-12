import 'package:flutter_dozor_city/core/domain/entities/route_result.dart';
import 'package:flutter_dozor_city/core/domain/entities/search_params.dart';
import 'package:flutter_dozor_city/core/domain/repositories/search_repository.dart';

class SearchRoutesUseCase {
  const SearchRoutesUseCase(this._searchRepository);

  final SearchRepository _searchRepository;

  Future<List<RouteResult>> call(SearchParams params) {
    return _searchRepository.searchRoutes(params);
  }
}
