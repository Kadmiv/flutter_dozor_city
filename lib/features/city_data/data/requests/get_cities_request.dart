import 'package:flutter_dozor_city/core/network/request/app_request.dart';

class GetCitiesRequest extends AppRequest {
  const GetCitiesRequest()
      : super(
          method: AppRequestMethod.get,
          path: '/ua/cities',
        );
}
