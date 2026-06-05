import 'dart:convert';

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

  List<Map<String, Object?>> _extractList(Object? raw) {
    final normalized = _normalizeRaw(raw);
    if (normalized is List) {
      return _objectList(normalized);
    }
    if (normalized is Map<String, Object?> && normalized['data'] is List) {
      return _objectList(normalized['data']);
    }
    throw FormatException('Unexpected response shape');
  }

  Map<String, Object?> _extractMap(Object? raw) {
    final normalized = _normalizeRaw(raw);
    if (normalized is Map<String, Object?>) {
      return normalized;
    }
    throw FormatException('Unexpected response shape');
  }

  Object? _normalizeRaw(Object? raw) {
    if (raw is String) {
      return jsonDecode(raw);
    }
    if (raw is List || raw is Map) {
      return raw;
    }
    throw FormatException('Unexpected response shape');
  }

  List<Map<String, Object?>> _objectList(Object? raw) {
    if (raw is! List) {
      return const [];
    }
    final result = <Map<String, Object?>>[];
    for (final item in raw) {
      final map = _objectMap(item);
      if (map != null) {
        result.add(map);
      }
    }
    return result;
  }

  Map<String, Object?>? _objectMap(Object? raw) {
    if (raw is Map<String, Object?>) {
      return raw;
    }
    if (raw is Map) {
      final result = <String, Object?>{};
      for (final entry in raw.entries) {
        result['${entry.key}'] = entry.value;
      }
      return result;
    }
    return null;
  }
}
