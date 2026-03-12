import 'package:dio/dio.dart';
import 'package:flutter_dozor_city/core/data/datasources/remote/search_remote_data_source.dart';
import 'package:flutter_dozor_city/core/data/fake_seed_data.dart';
import 'package:flutter_dozor_city/core/domain/entities/route_result.dart';
import 'package:flutter_dozor_city/core/domain/entities/search_params.dart';
import 'package:flutter_dozor_city/core/domain/entities/selected_point.dart';
import 'package:flutter_dozor_city/core/domain/repositories/search_repository.dart';

class SearchRepositoryImpl implements SearchRepository {
  SearchRepositoryImpl({required SearchRemoteDataSource remoteDataSource})
      : _remoteDataSource = remoteDataSource;

  final SearchRemoteDataSource _remoteDataSource;

  @override
  Future<SelectedPoint> getCurrentLocation() async {
    return const SelectedPoint(
      label: 'Поточне місцезнаходження',
      lat: 50.25465,
      lng: 28.65867,
      source: SelectedPointSource.gps,
    );
  }

  @override
  Future<List<RouteResult>> searchRoutes(SearchParams params) async {
    try {
      return await _remoteDataSource.searchRoutes(params);
    } on DioException {
      return FakeSeedData.searchResults(params);
    }
  }

  @override
  Future<List<SelectedPoint>> searchAddressSuggestions(String query) async {
    try {
      return await _remoteDataSource.searchAddressSuggestions(query);
    } on DioException {
      if (query.trim().isEmpty) {
        return const [];
      }
      return FakeSeedData.suggestions(query);
    }
  }
}
