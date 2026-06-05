import 'package:flutter_dozor_city/features/city_data/data/datasources/local/city_local_data_source.dart';
import 'package:dio/dio.dart';
import 'package:flutter_dozor_city/features/city_data/data/batumi/batumi_city_catalog.dart';
import 'package:flutter_dozor_city/features/city_data/data/datasources/remote/city_remote_data_source.dart';
import 'package:flutter_dozor_city/core/domain/entities/arrival_info.dart';
import 'package:flutter_dozor_city/core/domain/entities/city.dart';
import 'package:flutter_dozor_city/core/domain/entities/route_zone.dart';
import 'package:flutter_dozor_city/core/domain/entities/transport_route.dart';
import 'package:flutter_dozor_city/core/domain/repositories/city_repository.dart';
import 'package:flutter_dozor_city/core/domain/repositories/session_repository.dart';
import 'package:flutter_dozor_city/core/domain/entities/vehicle.dart';
import 'package:flutter_dozor_city/core/error/failures.dart';

import 'package:flutter_dozor_city/core/domain/repositories/cities_repository.dart';
import 'package:flutter_dozor_city/core/domain/repositories/city_data_freshness_repository.dart';
import 'package:flutter_dozor_city/core/domain/repositories/routes_repository.dart';
import 'package:flutter_dozor_city/core/domain/repositories/arrival_repository.dart';
import 'package:flutter_dozor_city/core/domain/repositories/vehicles_repository.dart';
import 'package:flutter_dozor_city/core/time/app_clock.dart';

class CityRepositoryImpl implements CityRepository, CitiesRepository, CityDataFreshnessRepository, RoutesRepository, ArrivalRepository, VehiclesRepository {
  static const _citiesCacheTtl = Duration(hours: 24);
  static const _routesCacheTtl = Duration(hours: 6);
  static const _zonesCacheTtl = Duration(hours: 6);
  static const _arrivalCacheTtl = Duration(seconds: 20);

  CityRepositoryImpl({
    required CityRemoteDataSource remoteDataSource,
    required CityLocalDataSource localDataSource,
    required SessionRepository sessionRepository,
    required AppClock clock,
  })  : _remoteDataSource = remoteDataSource,
        _localDataSource = localDataSource,
        _sessionRepository = sessionRepository,
        _clock = clock;

  final CityRemoteDataSource _remoteDataSource;
  final CityLocalDataSource _localDataSource;
  final SessionRepository _sessionRepository;
  final AppClock _clock;

  @override
  Future<bool> ensureCityDataFresh(String cityId) async {
    try {
      final remoteHash = await _remoteDataSource.getCityDataHash(cityId);
      final cachedHash = await _sessionRepository.getRoutesCacheHash(cityId);
      if (cachedHash == remoteHash) {
        return false;
      }
      await _localDataSource.clearCityData(cityId);
      await _sessionRepository.setRoutesCacheHash(cityId, remoteHash);
      return true;
    } on DioException {
      return false;
    }
  }

  @override
  Future<List<City>> getCities() async {
    final cached = await _localDataSource.getCities();
    final cachedUpdatedAt = await _localDataSource.getCitiesUpdatedAt();
    final cachedWithBatumi = cached.isEmpty ? cached : _ensureBatumiCity(cached);
    if (cachedWithBatumi.isNotEmpty && _isFresh(cachedUpdatedAt, _citiesCacheTtl)) {
      if (cachedWithBatumi.length != cached.length) {
        await _localDataSource.saveCities(cachedWithBatumi);
      }
      return cachedWithBatumi;
    }
    try {
      final cities = _ensureBatumiCity(await _remoteDataSource.getCities());
      await _localDataSource.saveCities(cities);
      return cities;
    } on DioException {
      if (cachedWithBatumi.isNotEmpty) {
        return cachedWithBatumi;
      }
      throw const NetworkFailure();
    }
  }

  @override
  Future<ArrivalInfo> getArrivalByZone({
    required String cityId,
    required String zoneId,
  }) async {
    final cachedArrival = await _localDataSource.getArrivalByZone(zoneId);
    final cachedUpdatedAt = await _localDataSource.getArrivalUpdatedAt(zoneId);
    if (cachedArrival != null && _isFresh(cachedUpdatedAt, _arrivalCacheTtl)) {
      return cachedArrival;
    }
    try {
      final arrival = await _remoteDataSource.getArrivalByZone(
        cityId: cityId,
        zoneId: zoneId,
      );
      await _localDataSource.saveArrivalByZone(arrival);
      return arrival;
    } on DioException {
      if (cachedArrival != null) {
        return cachedArrival;
      }
      throw const NetworkFailure();
    }
  }

  @override
  Future<List<Vehicle>> getCityVehicles(
    String cityId, {
    List<String>? routeIds,
  }) async {
    try {
      return await _remoteDataSource.getCityVehicles(cityId, routeIds: routeIds);
    } on DioException {
      throw const NetworkFailure();
    }
  }

  @override
  Future<List<TransportRoute>> getRoutesByType({
    required String cityId,
    required int transportType,
  }) async {
    final cached = await _localDataSource.getRoutesByType(
      cityId: cityId,
      transportType: transportType,
    );
    final cachedUpdatedAt = await _localDataSource.getRoutesByTypeUpdatedAt(
      cityId: cityId,
      transportType: transportType,
    );
    if (cached.isNotEmpty && _isFresh(cachedUpdatedAt, _routesCacheTtl)) {
      return cached;
    }
    try {
      final routes = await _remoteDataSource.getRoutesByType(
        cityId: cityId,
        transportType: transportType,
      );
      await _localDataSource.saveRoutesByType(
        cityId: cityId,
        transportType: transportType,
        routes: routes,
      );
      return routes;
    } on DioException {
      if (cached.isNotEmpty) {
        return cached;
      }
      throw const NetworkFailure();
    }
  }

  @override
  Future<List<RouteZone>> getRouteZones(String routeId) async {
    final cached = await _localDataSource.getRouteZones(routeId);
    final cachedUpdatedAt = await _localDataSource.getRouteZonesUpdatedAt(routeId);
    if (cached.isNotEmpty && _isFresh(cachedUpdatedAt, _zonesCacheTtl)) {
      return cached;
    }
    try {
      final zones = await _remoteDataSource.getRouteZones(routeId);
      await _localDataSource.saveRouteZones(routeId, zones);
      return zones;
    } on DioException {
      if (cached.isNotEmpty) {
        return cached;
      }
      throw const NetworkFailure();
    }
  }

  @override
  Future<void> preloadCityData(String cityId) async {
    try {
      await _remoteDataSource.preloadCityData(cityId);
      final remoteHash = await _remoteDataSource.getCityDataHash(cityId);
      await _sessionRepository.setRoutesCacheHash(cityId, remoteHash);
    } on DioException {
      return;
    }
  }

  bool _isFresh(DateTime? updatedAt, Duration ttl) {
    if (updatedAt == null) {
      return false;
    }
    return _clock.now().difference(updatedAt) <= ttl;
  }

  List<City> _ensureBatumiCity(List<City> cities) {
    final result = List<City>.from(cities);
    final hasBatumi = result.any((city) => city.id == BatumiCityCatalog.cityId);
    if (!hasBatumi) {
      result.add(BatumiCityCatalog.city);
    }
    return result;
  }
}
