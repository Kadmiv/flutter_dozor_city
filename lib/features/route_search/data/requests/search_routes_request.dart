import 'package:flutter_dozor_city/core/network/request/app_request.dart';

class SearchRoutesRequest extends AppRequest {
  SearchRoutesRequest({required String payload})
      : super(
          method: AppRequestMethod.get,
          path: '/data?t=4',
          queryParameters: {'p': payload},
        );
}
