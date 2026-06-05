import 'package:flutter_dozor_city/core/domain/entities/arrival_info.dart';

abstract class ArrivalRepository {
  Future<ArrivalInfo> getArrivalByZone({
    required String cityId,
    required String zoneId,
  });
}
