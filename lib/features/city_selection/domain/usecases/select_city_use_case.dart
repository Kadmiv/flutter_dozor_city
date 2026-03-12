import 'package:flutter_dozor_city/core/domain/entities/city.dart';
import 'package:flutter_dozor_city/core/domain/repositories/city_repository.dart';
import 'package:flutter_dozor_city/core/domain/repositories/session_repository.dart';
import 'package:flutter_dozor_city/features/city_selection/domain/usecases/check_city_data_freshness_use_case.dart';

class SelectCityUseCase {
  const SelectCityUseCase({
    required CityRepository cityRepository,
    required SessionRepository sessionRepository,
    required CheckCityDataFreshnessUseCase checkCityDataFreshnessUseCase,
  })  : _cityRepository = cityRepository,
        _sessionRepository = sessionRepository,
        _checkCityDataFreshnessUseCase = checkCityDataFreshnessUseCase;

  final CityRepository _cityRepository;
  final SessionRepository _sessionRepository;
  final CheckCityDataFreshnessUseCase _checkCityDataFreshnessUseCase;

  Future<void> call(City city) async {
    await _sessionRepository.setSelectedCity(city);
    await _checkCityDataFreshnessUseCase(city.id);
    await _cityRepository.preloadCityData(city.id);
  }
}
