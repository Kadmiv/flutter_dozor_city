import 'package:flutter_dozor_city/core/domain/repositories/city_repository.dart';
import 'package:flutter_dozor_city/features/live_tracking/domain/entities/vehicle_entity.dart';

class GetCityVehiclesUseCase {
  const GetCityVehiclesUseCase(this._cityRepository);

  final CityRepository _cityRepository;

  Future<List<VehicleEntity>> call(String cityId, {List<String>? routeIds}) {
    return _cityRepository.getCityVehicles(cityId, routeIds: routeIds);
  }
}
