import 'package:flutter_dozor_city/core/domain/repositories/city_repository.dart';
import 'package:flutter_dozor_city/core/domain/entities/vehicle.dart';

class GetCityVehiclesUseCase {
  const GetCityVehiclesUseCase(this._cityRepository);

  final CityRepository _cityRepository;

  Future<List<Vehicle>> call(String cityId, {List<String>? routeIds}) {
    return _cityRepository.getCityVehicles(cityId, routeIds: routeIds);
  }
}
