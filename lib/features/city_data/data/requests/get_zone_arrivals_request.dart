import 'package:flutter_dozor_city/core/network/request/app_request.dart';

class GetZoneArrivalsRequest extends AppRequest {
  GetZoneArrivalsRequest({required String cityId, required String zoneId})
      : super(
          method: AppRequestMethod.get,
          path: '/data?t=3',
          cityCookieId: cityId,
          queryParameters: {'p': zoneId},
        );
}
