import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter_dozor_city/core/network/dio_client.dart';
import 'package:flutter_dozor_city/features/point_select/data/models/selected_point_model.dart';
import 'package:flutter_dozor_city/features/route_search/data/models/response_routes_search_model.dart';
import 'package:flutter_dozor_city/features/route_search/data/requests/search_address_suggestions_request.dart';
import 'package:flutter_dozor_city/features/route_search/data/requests/search_routes_request.dart';

class SearchApi {
  SearchApi(this._dioClient);

  final DioClient _dioClient;

  Future<ResponseRoutesSearchModel> searchRoutes(SearchRoutesRequest request) async {
    final response = await _dioClient.request(request);
    final data = _extractMap(response.data);
    return ResponseRoutesSearchModel.fromJson(data);
  }

  Future<List<SelectedPointModel>> searchAddressSuggestions(
    SearchAddressSuggestionsRequest request,
  ) async {
    final response = await _dioClient.request(request);
    final data = _extractList(response.data);
    return data.map(SelectedPointModel.fromJson).toList(growable: false);
  }

  List<Map<String, dynamic>> _extractList(dynamic raw) {
    final normalized = _normalizeRaw(raw);
    if (normalized is List) {
      return normalized.whereType<Map>().map((item) => item.cast<String, dynamic>()).toList();
    }
    if (normalized is Map<String, dynamic> && normalized['data'] is List) {
      final data = normalized['data'] as List;
      return data.whereType<Map>().map((item) => item.cast<String, dynamic>()).toList();
    }
    throw DioException(
      requestOptions: RequestOptions(path: '/api/v1/geo/suggest'),
      message: 'Unexpected response shape',
    );
  }

  Map<String, dynamic> _extractMap(dynamic raw) {
    final normalized = _normalizeRaw(raw);
    if (normalized is Map<String, dynamic>) {
      return normalized;
    }
    throw DioException(
      requestOptions: RequestOptions(path: '/data?t=4'),
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
      requestOptions: RequestOptions(path: '/data?t=4'),
      message: 'Unexpected response shape',
    );
  }
}
