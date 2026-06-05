import 'package:dio/dio.dart';
import 'package:flutter_dozor_city/core/domain/entities/arrival_info.dart';
import 'package:flutter_dozor_city/core/domain/entities/city.dart';
import 'package:flutter_dozor_city/core/domain/entities/route_zone.dart';
import 'package:flutter_dozor_city/core/domain/entities/transport_route.dart';
import 'package:flutter_dozor_city/core/domain/entities/vehicle.dart';
import 'package:flutter_dozor_city/core/network/api_paths.dart';
import 'package:flutter_dozor_city/core/network/dio_client.dart';
import 'package:flutter_dozor_city/features/city_data/data/api/city_api.dart';
import 'package:flutter_dozor_city/features/city_data/data/datasources/remote/city_remote_data_source.dart';
import 'package:flutter_dozor_city/features/city_data/data/models/response_t1_data_dto.dart';
import 'package:flutter_dozor_city/features/city_data/data/resolvers/transport_type_resolver.dart';
import 'package:flutter_dozor_city/features/city_data/data/requests/get_city_devices_request.dart';
import 'package:flutter_dozor_city/features/city_data/data/requests/get_city_hash_request.dart';
import 'package:flutter_dozor_city/features/city_data/data/requests/get_city_routes_request.dart';
import 'package:flutter_dozor_city/features/city_data/data/requests/get_cities_request.dart';
import 'package:flutter_dozor_city/features/city_data/data/requests/get_zone_arrivals_request.dart';

class DioCityRemoteDataSource implements CityRemoteDataSource {
  DioCityRemoteDataSource(this._dioClient) : _cityApi = CityApi(_dioClient);

  final DioClient _dioClient;
  final CityApi _cityApi;
  final Map<String, ResponseT1DataModel> _t1CacheByCity = {};
  final Map<String, String> _routeCityIndex = {};

  Never _throwUnsupportedWebLegacyApi(String cityId) {
    throw UnsupportedError(
      'Legacy Dozor City API for city "$cityId" requires the cross-origin '
      'cookie "gts.web.city". Browsers do not allow Flutter Web to set that '
      'cookie header for ${ApiPaths.baseUrl}. Use Android/iOS/desktop or '
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
    final cities = await _cityApi.getCities(const GetCitiesRequest());
    return cities.map((dto) => dto.toEntity()).toList(growable: false);
  }

  @override
  Future<int> getCityDataHash(String cityId) async {
    _ensureLegacyCityCookieSupported(cityId);
    return _cityApi.getCityDataHash(GetCityHashRequest(cityId: cityId));
  }

  @override
  Future<List<Vehicle>> getCityVehicles(
    String cityId, {
    List<String>? routeIds,
  }) async {
    _ensureLegacyCityCookieSupported(cityId);
    final t1 = await _getOrLoadT1(cityId);
    final routesById = {
      for (final route in t1.routes) '${route.id}': route,
    };
    final payload = routeIds?.isNotEmpty == true
        ? routeIds!.join(',')
        : routesById.keys.join(',');
    final t2 = await _cityApi.getCityVehicles(
      GetCityDevicesRequest(cityId: cityId, payload: payload),
    );
    return t2.routes
        .expand((routeDevices) {
          final routeId = '${routeDevices.routeId}';
          final route = routesById[routeId];
          final transportType = route == null ? 0 : TransportTypeResolver.resolve(route);
          final routeShortName = route?.shortName ?? routeId;
          final routeTitle = route?.names.join(' / ') ?? route?.info ?? 'Маршрут $routeId';
          return routeDevices.devices.map(
            (device) => Vehicle(
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
        })
        .toList(growable: false);
  }

  @override
  Future<ArrivalInfo> getArrivalByZone({
    required String cityId,
    required String zoneId,
  }) async {
    _ensureLegacyCityCookieSupported(cityId);
    final arrival = await _cityApi.getArrivalByZone(
      GetZoneArrivalsRequest(cityId: cityId, zoneId: zoneId),
    );
    return arrival.toEntity();
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
        .map((dto) => dto.toEntity(transportType: transportType))
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
    final response = await _cityApi.getCityRoutes(
      GetCityRoutesRequest(cityId: cityId),
    );
    _t1CacheByCity[cityId] = response;
    for (final route in response.routes) {
      _routeCityIndex['${route.id}'] = cityId;
    }
    return response;
  }

  dynamic _findRouteById(ResponseT1DataModel t1, String routeId) {
    for (final route in t1.routes) {
      if ('${route.id}' == routeId) {
        return route;
      }
    }
    return null;
  }
}
