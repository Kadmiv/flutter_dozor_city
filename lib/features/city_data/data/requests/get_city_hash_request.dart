import 'package:flutter_dozor_city/core/network/request/app_request.dart';

class GetCityHashRequest extends AppRequest {
  GetCityHashRequest({required String cityId})
      : super(
          method: AppRequestMethod.get,
          path: '/data?t=1',
          cityCookieId: cityId,
        );
}
