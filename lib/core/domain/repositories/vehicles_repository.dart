import 'package:flutter_dozor_city/core/domain/entities/vehicle.dart';

abstract class VehiclesRepository {
  Future<List<Vehicle>> getCityVehicles(String cityId, {List<String>? routeIds});
}
