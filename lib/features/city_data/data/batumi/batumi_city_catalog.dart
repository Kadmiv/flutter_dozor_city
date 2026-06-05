import 'package:flutter_dozor_city/core/domain/entities/city.dart';

abstract final class BatumiCityCatalog {
  static const String cityId = 'batumi';

  static const City city = City(
    id: cityId,
    name: 'Батуми',
    region: 'Аджария',
    centerLat: 41.6168,
    centerLng: 41.6367,
    zoom: 12.5,
  );
}
