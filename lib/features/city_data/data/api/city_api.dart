import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter_dozor_city/core/network/dio_client.dart';
import 'package:flutter_dozor_city/features/city_data/data/models/arrival_info_dto.dart';
import 'package:flutter_dozor_city/features/city_data/data/models/city_dto.dart';
import 'package:flutter_dozor_city/features/city_data/data/models/response_t1_data_dto.dart';
import 'package:flutter_dozor_city/features/city_data/data/models/response_t2_data_dto.dart';
import 'package:flutter_dozor_city/features/city_data/data/models/response_t3_data_dto.dart';
import 'package:flutter_dozor_city/features/city_data/data/models/response_t_hash_dto.dart';
import 'package:flutter_dozor_city/features/city_data/data/requests/get_cities_request.dart';
import 'package:flutter_dozor_city/features/city_data/data/requests/get_city_devices_request.dart';
import 'package:flutter_dozor_city/features/city_data/data/requests/get_city_hash_request.dart';
import 'package:flutter_dozor_city/features/city_data/data/requests/get_city_routes_request.dart';
import 'package:flutter_dozor_city/features/city_data/data/requests/get_zone_arrivals_request.dart';

class CityApi {
  CityApi(this._dioClient);

  final DioClient _dioClient;

  Future<List<CityModel>> getCities(GetCitiesRequest request) async {
    final response = await _dioClient.request(request);
    final data = _extractList(response.data);
    return data.map((item) => CityModel.fromJson(item)).toList(growable: false);
  }

  Future<int> getCityDataHash(GetCityHashRequest request) async {
    final response = await _dioClient.request(request);
    final data = _extractMap(response.data);
    return ResponseTHashModel.fromJson(data).hash;
  }

  Future<ResponseT1DataModel> getCityRoutes(GetCityRoutesRequest request) async {
    final response = await _dioClient.request(request);
    final data = _extractMap(response.data);
    return ResponseT1DataModel.fromJson(data);
  }

  Future<ResponseT2DataModel> getCityVehicles(GetCityDevicesRequest request) async {
    final response = await _dioClient.request(request);
    final data = _extractMap(response.data);
    return ResponseT2DataModel.fromJson(data);
  }

  Future<ArrivalInfoModel> getArrivalByZone(GetZoneArrivalsRequest request) async {
    final response = await _dioClient.request(request);
    final data = _extractMap(response.data);
    return ResponseT3DataModel.fromJson(
      zoneId: request.queryParameters?['p'] as String? ?? '',
      json: data,
    ).arrivalInfo;
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
      requestOptions: RequestOptions(path: '/ua/cities'),
      message: 'Unexpected response shape',
    );
  }

  Map<String, dynamic> _extractMap(dynamic raw) {
    final normalized = _normalizeRaw(raw);
    if (normalized is Map<String, dynamic>) {
      return normalized;
    }
    throw DioException(
      requestOptions: RequestOptions(path: '/data'),
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
      requestOptions: RequestOptions(path: '/data'),
      message: 'Unexpected response shape',
    );
  }
}
