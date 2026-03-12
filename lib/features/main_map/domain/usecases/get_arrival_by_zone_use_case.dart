import 'package:flutter_dozor_city/core/domain/entities/arrival_info.dart';
import 'package:flutter_dozor_city/core/domain/repositories/city_repository.dart';

class GetArrivalByZoneUseCase {
  const GetArrivalByZoneUseCase(this._cityRepository);

  final CityRepository _cityRepository;

  Future<ArrivalInfo> call({
    required String cityId,
    required String zoneId,
  }) {
    return _cityRepository.getArrivalByZone(
      cityId: cityId,
      zoneId: zoneId,
    );
  }
}
