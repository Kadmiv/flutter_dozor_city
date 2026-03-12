import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter_dozor_city/core/data/datasources/remote/city_remote_data_source.dart';
import 'package:flutter_dozor_city/core/data/models/city_model.dart';
import 'package:flutter_dozor_city/core/data/models/json_route_model.dart';
import 'package:flutter_dozor_city/core/data/models/response_t1_data_model.dart';
import 'package:flutter_dozor_city/core/data/models/response_t2_data_model.dart';
import 'package:flutter_dozor_city/core/data/models/response_t3_data_model.dart';
import 'package:flutter_dozor_city/core/data/models/response_t_hash_model.dart';
import 'package:flutter_dozor_city/core/data/resolvers/transport_type_resolver.dart';
import 'package:flutter_dozor_city/core/domain/entities/arrival_info.dart';
import 'package:flutter_dozor_city/core/domain/entities/city.dart';
import 'package:flutter_dozor_city/core/domain/entities/route_zone.dart';
import 'package:flutter_dozor_city/core/domain/entities/transport_route.dart';
import 'package:flutter_dozor_city/core/network/api_paths.dart';
import 'package:flutter_dozor_city/core/network/dio_client.dart';
import 'package:flutter_dozor_city/features/live_tracking/domain/entities/vehicle_entity.dart';

class DioCityRemoteDataSource implements CityRemoteDataSource {
  DioCityRemoteDataSource(this._dioClient);

  final DioClient _dioClient;
  final Map<String, ResponseT1DataModel> _t1CacheByCity = {};
  final Map<String, String> _routeCityIndex = {};

  Never _throwUnsupportedWebLegacyApi(String cityId) {
    throw UnsupportedError(
      'Legacy Dozor City API for city "$cityId" requires the cross-origin '
      'cookie "gts.web.city". Browsers do not allow Flutter Web to set that '
      'cookie header for https://city.dozor.tech. Use Android/iOS/desktop or '
      'put a same-origin proxy/backend in front of city.dozor.tech.',
    );
  }

  void _ensureLegacyCityCookieSupported(String cityId) {
    if (!_dioClient.supportsLegacyCityCookie) {
      _throwUnsupportedWebLegacyApi(cityId);
    }
  }

  @override
  Future<List<City>> getCities() async {
    final response = await _dioClient.dio.get<dynamic>(ApiPaths.cities());
    final data = _extractList(response.data);
    return data
        .map((item) => CityModel.fromJson(item).toEntity())
        .toList(growable: false);
  }

  @override
  Future<int> getCityDataHash(String cityId) async {
    _ensureLegacyCityCookieSupported(cityId);
    final response = await _dioClient.dio.get<dynamic>(
      ApiPaths.cityRoutes(),
      options: _dioClient.cityCookieOptions(cityId),
    );
    final data = _extractMap(response.data);
    return ResponseTHashModel.fromJson(data).hash;
  }

  @override
  Future<List<VehicleEntity>> getCityVehicles(
    String cityId, {
    List<String>? routeIds,
  }) async {
    _ensureLegacyCityCookieSupported(cityId);
    final t1 = await _getOrLoadT1(cityId);
    final routesById = {
      for (final route in t1.routes) '${route.id}': route,
    };
    final p = routeIds?.isNotEmpty == true
        ? routeIds!.join(',')
        : routesById.keys.join(',');
    final response = await _dioClient.dio.get<dynamic>(
      ApiPaths.cityDevices(),
      queryParameters: {
        'p': p,
      },
      options: _dioClient.cityCookieOptions(cityId),
    );
    final data = _extractMap(response.data);
    final t2 = ResponseT2DataModel.fromJson(data);
    return t2.routes
        .expand(
          (routeDevices) {
            final routeId = '${routeDevices.routeId}';
            final route = routesById[routeId];
            final transportType = route == null
                ? 0
                : TransportTypeResolver.resolve(route);
            final routeShortName = route?.shortName ?? routeId;
            final routeTitle =
                route?.names.join(' / ') ?? route?.info ?? 'Маршрут $routeId';
            return routeDevices.devices.map(
              (device) => VehicleEntity(
                id: '${device.id}',
                routeId: routeId,
                routeShortName: routeShortName,
                routeTitle: routeTitle,
                transportType: transportType,
                lat: device.location.lat,
                lng: device.location.lng,
                azimuth: device.azimuth,
                speed: device.speed,
                govNumber: device.govNumber,
              ),
            );
          },
        )
        .toList(growable: false);
  }

  @override
  Future<ArrivalInfo> getArrivalByZone({
    required String cityId,
    required String zoneId,
  }) async {
    _ensureLegacyCityCookieSupported(cityId);
    final response = await _dioClient.dio.get<dynamic>(
      ApiPaths.zoneArrivals(),
      queryParameters: {
        'p': zoneId,
      },
      options: _dioClient.cityCookieOptions(cityId),
    );
    final data = _extractMap(response.data);
    return ResponseT3DataModel.fromJson(zoneId: zoneId, json: data).arrivalInfo;
  }

  @override
  Future<List<TransportRoute>> getRoutesByType({
    required String cityId,
    required int transportType,
  }) async {
    _ensureLegacyCityCookieSupported(cityId);
    final t1 = await _getOrLoadT1(cityId);
    return t1.routes
        .where((route) => TransportTypeResolver.resolve(route) == transportType)
        .map((item) => item.toEntity(transportType: transportType))
        .toList(growable: false);
  }

  @override
  Future<List<RouteZone>> getRouteZones(String routeId) async {
    final cityId = _routeCityIndex[routeId];
    if (cityId == null) {
      throw DioException(
        requestOptions: RequestOptions(path: ApiPaths.cityRoutes()),
        message: 'Route $routeId is not present in cached T1 snapshot',
      );
    }
    final t1 = await _getOrLoadT1(cityId);
    final route = _findRouteById(t1, routeId);
    if (route == null) {
      throw DioException(
        requestOptions: RequestOptions(path: ApiPaths.cityRoutes()),
        message: 'Route $routeId is not present in T1 snapshot',
      );
    }
    return route.zones
        .map((zone) => zone.toEntity(routeId: routeId))
        .toList(growable: false);
  }

  @override
  Future<void> preloadCityData(String cityId) async {
    _ensureLegacyCityCookieSupported(cityId);
    await _getOrLoadT1(cityId, forceReload: true);
  }

  Future<ResponseT1DataModel> _getOrLoadT1(
    String cityId, {
    bool forceReload = false,
  }) async {
    if (!forceReload && _t1CacheByCity.containsKey(cityId)) {
      return _t1CacheByCity[cityId]!;
    }
    final response = await _dioClient.dio.get<dynamic>(
      ApiPaths.cityRoutes(),
      options: _dioClient.cityCookieOptions(cityId),
    );
    final data = _extractMap(response.data);
    final t1 = ResponseT1DataModel.fromJson(data);
    _t1CacheByCity[cityId] = t1;
    for (final route in t1.routes) {
      _routeCityIndex['${route.id}'] = cityId;
    }
    return t1;
  }

  JsonRouteModel? _findRouteById(ResponseT1DataModel t1, String routeId) {
    for (final route in t1.routes) {
      if ('${route.id}' == routeId) {
        return route;
      }
    }
    return null;
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
      requestOptions: RequestOptions(path: ApiPaths.cityRoutes()),
      message: 'Unexpected response shape',
    );
  }

  Map<String, dynamic> _extractMap(dynamic raw) {
    final normalized = _normalizeRaw(raw);
    if (normalized is Map<String, dynamic>) {
      if (normalized['data'] is Map<String, dynamic>) {
        return normalized['data'] as Map<String, dynamic>;
      }
      return normalized;
    }
    throw DioException(
      requestOptions: RequestOptions(path: ApiPaths.cityRoutes()),
      message: 'Unexpected response shape',
    );
  }

  dynamic _normalizeRaw(dynamic raw) {
    if (raw is String) {
      return jsonDecode(raw);
    }
    if (raw is List) {
      return raw;
    }
    if (raw is Map<String, dynamic>) {
      return raw;
    }
    throw DioException(
      requestOptions: RequestOptions(path: ApiPaths.cityRoutes()),
      message: 'Unexpected response shape',
    );
  }
}
