import 'package:flutter_dozor_city/core/domain/entities/route_result.dart';
import 'package:flutter_dozor_city/core/domain/entities/search_params.dart';
import 'package:flutter_dozor_city/core/domain/entities/selected_point.dart';
import 'package:flutter_dozor_city/core/network/dio_client.dart';
import 'package:flutter_dozor_city/features/route_search/data/api/search_api.dart';
import 'package:flutter_dozor_city/features/route_search/data/datasources/remote/search_remote_data_source.dart';
import 'package:flutter_dozor_city/features/route_search/data/mappers/search_route_result_mapper.dart';
import 'package:flutter_dozor_city/features/route_search/data/requests/search_address_suggestions_request.dart';
import 'package:flutter_dozor_city/features/route_search/data/requests/search_routes_request.dart';

class DioSearchRemoteDataSource implements SearchRemoteDataSource {
  DioSearchRemoteDataSource(
    DioClient dioClient, {
    SearchRouteResultMapper searchRouteResultMapper =
        const SearchRouteResultMapper(),
  })  : _searchRouteResultMapper = searchRouteResultMapper,
        _searchApi = SearchApi(dioClient);

  final SearchApi _searchApi;
  final SearchRouteResultMapper _searchRouteResultMapper;

  @override
  Future<SelectedPoint> getCurrentLocation() async {
    throw UnimplementedError('Current location should come from device services');
  }

  @override
  Future<List<RouteResult>> searchRoutes(SearchParams params) async {
    final request = SearchRoutesRequest(
      payload: _buildLegacySearchPayload(params),
    );
    final response = await _searchApi.searchRoutes(request);
    return response.results
        .asMap()
        .entries
        .map((entry) => _searchRouteResultMapper.map(model: entry.value, index: entry.key))
        .toList(growable: false);
  }

  @override
  Future<List<SelectedPoint>> searchAddressSuggestions(String query) async {
    final response = await _searchApi.searchAddressSuggestions(
      SearchAddressSuggestionsRequest(query: query),
    );
    return response.map((dto) => dto.toEntity()).toList(growable: false);
  }

  String _buildLegacySearchPayload(SearchParams params) {
    final flags = List<String>.generate(
      5,
      (index) => params.transportTypes.contains(index) ? '1' : '0',
      growable: false,
    );
    return '${params.start.lng},${params.start.lat},'
        '${params.end.lng},${params.end.lat},'
        '${flags.join('-')}';
  }
}
