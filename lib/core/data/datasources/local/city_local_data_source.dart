import 'package:flutter_dozor_city/core/domain/entities/arrival_info.dart';
import 'package:flutter_dozor_city/core/domain/entities/city.dart';
import 'package:flutter_dozor_city/core/domain/entities/route_zone.dart';
import 'package:flutter_dozor_city/core/domain/entities/transport_route.dart';

abstract class CityLocalDataSource {
  Future<List<City>> getCities();
  Future<DateTime?> getCitiesUpdatedAt();
  Future<void> saveCities(List<City> cities);

  Future<List<TransportRoute>> getRoutesByType({
    required String cityId,
    required int transportType,
  });
  Future<DateTime?> getRoutesByTypeUpdatedAt({
    required String cityId,
    required int transportType,
  });
  Future<void> saveRoutesByType({
    required String cityId,
    required int transportType,
    required List<TransportRoute> routes,
  });

  Future<List<RouteZone>> getRouteZones(String routeId);
  Future<DateTime?> getRouteZonesUpdatedAt(String routeId);
  Future<void> saveRouteZones(String routeId, List<RouteZone> zones);

  Future<ArrivalInfo?> getArrivalByZone(String zoneId);
  Future<DateTime?> getArrivalUpdatedAt(String zoneId);
  Future<void> saveArrivalByZone(ArrivalInfo arrivalInfo);
  Future<void> clearCityData(String cityId);
}
