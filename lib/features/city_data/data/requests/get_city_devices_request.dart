import 'package:flutter_dozor_city/core/network/request/app_request.dart';

class GetCityDevicesRequest extends AppRequest {
  GetCityDevicesRequest({required String cityId, required String payload})
      : super(
          method: AppRequestMethod.get,
          path: '/data?t=2',
          cityCookieId: cityId,
          queryParameters: {'p': payload},
        );
}
