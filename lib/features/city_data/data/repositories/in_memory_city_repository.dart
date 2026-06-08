import 'package:flutter_dozor_city/core/domain/entities/arrival_info.dart';
import 'package:flutter_dozor_city/core/data/fake_seed_data.dart';
import 'package:flutter_dozor_city/core/domain/entities/city.dart';
import 'package:flutter_dozor_city/core/domain/entities/route_zone.dart';
import 'package:flutter_dozor_city/core/domain/entities/transport_route.dart';
import 'package:flutter_dozor_city/core/domain/repositories/city_repository.dart';
import 'package:flutter_dozor_city/core/domain/entities/vehicle.dart';

import 'package:flutter_dozor_city/core/domain/repositories/cities_repository.dart';
import 'package:flutter_dozor_city/core/domain/repositories/city_data_freshness_repository.dart';
import 'package:flutter_dozor_city/core/domain/repositories/routes_repository.dart';
import 'package:flutter_dozor_city/core/domain/repositories/arrival_repository.dart';
import 'package:flutter_dozor_city/core/domain/repositories/vehicles_repository.dart';

class InMemoryCityRepository implements CityRepository, CitiesRepository, CityDataFreshnessRepository, RoutesRepository, ArrivalRepository, VehiclesRepository {
  @override
  Future<bool> ensureCityDataFresh(String cityId) async => false;

  @override
  Future<ArrivalInfo> getArrivalByZone({
    required String cityId,
    required String zoneId,
  }) async {
    return FakeSeedData.arrival(zoneId);
  }

  @override
  Future<List<Vehicle>> getCityVehicles(
    String cityId, {
    List<String>? routeIds,
  }) async {
    return FakeSeedData.cityVehicles(cityId);
  }

  @override
  Future<List<City>> getCities() async => FakeSeedData.cities;

  @override
  Future<List<TransportRoute>> getRoutesByType({
    required String cityId,
    required int transportType,
  }) async {
    return FakeSeedData.routesByType(
      cityId: cityId,
      transportType: transportType,
    );
  }

  @override
  Future<List<RouteZone>> getRouteZones(String routeId) async {
    return FakeSeedData.routeZones(routeId);
  }

  @override
  Future<List<RouteZone>> getCityStops(String cityId) async {
    return FakeSeedData.cityStops(cityId);
  }

  @override
  Future<void> preloadCityData(String cityId) async {}
}
