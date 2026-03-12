import 'package:flutter_dozor_city/core/domain/entities/arrival_info.dart';
import 'package:flutter_dozor_city/core/domain/entities/city.dart';
import 'package:flutter_dozor_city/core/domain/entities/route_zone.dart';
import 'package:flutter_dozor_city/core/domain/entities/transport_route.dart';
import 'package:flutter_dozor_city/features/live_tracking/domain/entities/vehicle_entity.dart';

abstract class CityRemoteDataSource {
  Future<List<City>> getCities();
  Future<void> preloadCityData(String cityId);
  Future<int> getCityDataHash(String cityId);
  Future<List<VehicleEntity>> getCityVehicles(String cityId, {List<String>? routeIds});
  Future<List<TransportRoute>> getRoutesByType({
    required String cityId,
    required int transportType,
  });
  Future<List<RouteZone>> getRouteZones(String routeId);
  Future<ArrivalInfo> getArrivalByZone({
    required String cityId,
    required String zoneId,
  });
}
