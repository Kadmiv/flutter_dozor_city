import 'package:flutter_dozor_city/core/domain/entities/city.dart';

abstract class CitiesRepository {
  Future<List<City>> getCities();
  Future<void> preloadCityData(String cityId);
}
