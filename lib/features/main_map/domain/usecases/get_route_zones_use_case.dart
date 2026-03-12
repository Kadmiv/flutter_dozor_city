import 'package:flutter_dozor_city/core/domain/entities/route_zone.dart';
import 'package:flutter_dozor_city/core/domain/repositories/city_repository.dart';

class GetRouteZonesUseCase {
  const GetRouteZonesUseCase(this._cityRepository);

  final CityRepository _cityRepository;

  Future<List<RouteZone>> call(String routeId) {
    return _cityRepository.getRouteZones(routeId);
  }
}
