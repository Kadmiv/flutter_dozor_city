import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter_dozor_city/core/data/datasources/remote/search_remote_data_source.dart';
import 'package:flutter_dozor_city/core/data/mappers/search_route_result_mapper.dart';
import 'package:flutter_dozor_city/core/data/models/selected_point_model.dart';
import 'package:flutter_dozor_city/core/data/models/response_routes_search_model.dart';
import 'package:flutter_dozor_city/core/domain/entities/route_result.dart';
import 'package:flutter_dozor_city/core/domain/entities/search_params.dart';
import 'package:flutter_dozor_city/core/domain/entities/selected_point.dart';
import 'package:flutter_dozor_city/core/network/api_paths.dart';
import 'package:flutter_dozor_city/core/network/dio_client.dart';

class DioSearchRemoteDataSource implements SearchRemoteDataSource {
  DioSearchRemoteDataSource(
    this._dioClient, {
    SearchRouteResultMapper searchRouteResultMapper =
        const SearchRouteResultMapper(),
  }) : _searchRouteResultMapper = searchRouteResultMapper;

  final DioClient _dioClient;
  final SearchRouteResultMapper _searchRouteResultMapper;

  @override
  Future<SelectedPoint> getCurrentLocation() async {
    throw UnimplementedError('Current location should come from device services');
  }

  @override
  Future<List<RouteResult>> searchRoutes(SearchParams params) async {
    final response = await _dioClient.dio.get<dynamic>(
      ApiPaths.routeSearch(),
      queryParameters: {
        'p': _buildLegacySearchPayload(params),
      },
    );
    final data = _extractMap(response.data);
    final searchResponse = ResponseRoutesSearchModel.fromJson(data);
    return searchResponse.results
        .asMap()
        .entries
        .map((entry) => _searchRouteResultMapper.map(model: entry.value, index: entry.key))
        .toList(growable: false);
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

  @override
  Future<List<SelectedPoint>> searchAddressSuggestions(String query) async {
    final response = await _dioClient.dio.get<dynamic>(
      ApiPaths.addressSuggest(),
      queryParameters: {'query': query},
    );
    final data = _extractList(response.data);
    return data
        .map((item) => SelectedPointModel.fromJson(item).toEntity())
        .toList(growable: false);
  }

  List<Map<String, dynamic>> _extractList(dynamic raw) {
    final normalized = _normalizeRaw(raw);
    if (normalized is List) {
      return normalized
          .whereType<Map>()
          .map((item) => item.cast<String, dynamic>())
          .toList();
    }
    if (normalized is Map<String, dynamic> && normalized['data'] is List) {
      final data = normalized['data'] as List;
      return data.whereType<Map>().map((item) => item.cast<String, dynamic>()).toList();
    }
    throw DioException(
      requestOptions: RequestOptions(path: ApiPaths.routeSearch()),
      message: 'Unexpected response shape',
    );
  }

  Map<String, dynamic> _extractMap(dynamic raw) {
    final normalized = _normalizeRaw(raw);
    if (normalized is Map<String, dynamic>) {
      return normalized;
    }
    throw DioException(
      requestOptions: RequestOptions(path: ApiPaths.routeSearch()),
      message: 'Unexpected response shape',
    );
  }

  dynamic _normalizeRaw(dynamic raw) {
    if (raw is String) {
      return jsonDecode(raw);
    }
    if (raw is List || raw is Map<String, dynamic>) {
      return raw;
    }
    throw DioException(
      requestOptions: RequestOptions(path: ApiPaths.routeSearch()),
      message: 'Unexpected response shape',
    );
  }
}
