import 'package:flutter_dozor_city/core/network/request/app_request.dart';

class GetCityRoutesRequest extends AppRequest {
  GetCityRoutesRequest({required String cityId})
      : super(
          method: AppRequestMethod.get,
          path: '/data?t=1',
          cityCookieId: cityId,
        );
}
