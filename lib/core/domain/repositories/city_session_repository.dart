import 'package:flutter/foundation.dart';
import 'package:flutter_dozor_city/core/domain/entities/city.dart';

abstract class CitySessionRepository extends Listenable {
  City? get selectedCity;
  bool get hasSelectedCity;
  Future<void> setSelectedCity(City city);
}
