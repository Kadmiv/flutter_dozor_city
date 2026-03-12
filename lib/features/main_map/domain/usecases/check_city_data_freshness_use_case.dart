import 'package:flutter_dozor_city/core/domain/repositories/city_repository.dart';

class CheckMainMapCityDataFreshnessUseCase {
  const CheckMainMapCityDataFreshnessUseCase(this._cityRepository);

  final CityRepository _cityRepository;

  Future<bool> call(String cityId) {
    return _cityRepository.ensureCityDataFresh(cityId);
  }
}
