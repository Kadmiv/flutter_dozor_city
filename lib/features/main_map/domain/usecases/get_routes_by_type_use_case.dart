import 'package:flutter_dozor_city/core/domain/entities/transport_route.dart';
import 'package:flutter_dozor_city/core/domain/repositories/city_repository.dart';

class GetRoutesByTypeUseCase {
  const GetRoutesByTypeUseCase(this._cityRepository);

  final CityRepository _cityRepository;

  Future<List<TransportRoute>> call({
    required String cityId,
    required int transportType,
  }) {
    return _cityRepository.getRoutesByType(
      cityId: cityId,
      transportType: transportType,
    );
  }
}
