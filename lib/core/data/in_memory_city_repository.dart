import 'package:flutter_dozor_city/core/domain/entities/arrival_info.dart';
import 'package:flutter_dozor_city/core/data/fake_seed_data.dart';
import 'package:flutter_dozor_city/core/domain/entities/city.dart';
import 'package:flutter_dozor_city/core/domain/entities/route_zone.dart';
import 'package:flutter_dozor_city/core/domain/entities/transport_route.dart';
import 'package:flutter_dozor_city/core/domain/repositories/city_repository.dart';
import 'package:flutter_dozor_city/features/live_tracking/domain/entities/vehicle_entity.dart';

class InMemoryCityRepository implements CityRepository {
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
  Future<List<VehicleEntity>> getCityVehicles(
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
  Future<void> preloadCityData(String cityId) async {}
}
