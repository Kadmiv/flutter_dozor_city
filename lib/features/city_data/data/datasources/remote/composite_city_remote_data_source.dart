import 'package:flutter_dozor_city/core/domain/entities/arrival_info.dart';
import 'package:flutter_dozor_city/core/domain/entities/city.dart';
import 'package:flutter_dozor_city/core/domain/entities/route_zone.dart';
import 'package:flutter_dozor_city/core/domain/entities/transport_route.dart';
import 'package:flutter_dozor_city/core/domain/entities/vehicle.dart';
import 'package:flutter_dozor_city/features/city_data/data/batumi/batumi_city_catalog.dart';
import 'package:flutter_dozor_city/features/city_data/data/datasources/remote/batumi_remote_data_source.dart';
import 'package:flutter_dozor_city/features/city_data/data/datasources/remote/city_remote_data_source.dart';

class CompositeCityRemoteDataSource implements CityRemoteDataSource {
  CompositeCityRemoteDataSource({
    required CityRemoteDataSource dozorRemoteDataSource,
    required BatumiRemoteDataSource batumiRemoteDataSource,
  })  : _dozorRemoteDataSource = dozorRemoteDataSource,
        _batumiRemoteDataSource = batumiRemoteDataSource;

  final CityRemoteDataSource _dozorRemoteDataSource;
  final BatumiRemoteDataSource _batumiRemoteDataSource;

  @override
  Future<List<City>> getCities() async {
    final cities = <City>[
      ...await _dozorRemoteDataSource.getCities(),
      ...await _batumiRemoteDataSource.getCities(),
    ];
    final seen = <String>{};
    return cities.where((city) => seen.add(city.id)).toList(growable: false);
  }

  @override
  Future<void> preloadCityData(String cityId) {
    return _remoteFor(cityId).preloadCityData(cityId);
  }

  @override
  Future<int> getCityDataHash(String cityId) {
    return _remoteFor(cityId).getCityDataHash(cityId);
  }

  @override
  Future<List<Vehicle>> getCityVehicles(
    String cityId, {
    List<String>? routeIds,
  }) {
    return _remoteFor(cityId).getCityVehicles(cityId, routeIds: routeIds);
  }

  @override
  Future<List<TransportRoute>> getRoutesByType({
    required String cityId,
    required int transportType,
  }) {
    return _remoteFor(cityId).getRoutesByType(
      cityId: cityId,
      transportType: transportType,
    );
  }

  @override
  Future<List<RouteZone>> getRouteZones(String routeId) async {
    try {
      final zones = await _dozorRemoteDataSource.getRouteZones(routeId);
      if (zones.isNotEmpty) {
        return zones;
      }
    } catch (_) {
      // Fallback below.
    }
    return _batumiRemoteDataSource.getRouteZones(routeId);
  }

  @override
  Future<ArrivalInfo> getArrivalByZone({
    required String cityId,
    required String zoneId,
  }) {
    return _remoteFor(cityId).getArrivalByZone(cityId: cityId, zoneId: zoneId);
  }

  CityRemoteDataSource _remoteFor(String cityId) {
    if (cityId == BatumiCityCatalog.cityId) {
      return _batumiRemoteDataSource;
    }
    return _dozorRemoteDataSource;
  }

}
