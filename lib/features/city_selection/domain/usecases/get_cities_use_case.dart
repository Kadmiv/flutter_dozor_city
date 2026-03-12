import 'package:flutter_dozor_city/core/domain/entities/city.dart';
import 'package:flutter_dozor_city/core/domain/repositories/city_repository.dart';

class GetCitiesUseCase {
  const GetCitiesUseCase(this._cityRepository);

  final CityRepository _cityRepository;

  Future<List<City>> call() {
    return _cityRepository.getCities();
  }
}
