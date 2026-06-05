import 'package:flutter_dozor_city/core/network/request/app_request.dart';

class SearchAddressSuggestionsRequest extends AppRequest {
  SearchAddressSuggestionsRequest({required String query})
      : super(
          method: AppRequestMethod.get,
          path: '/api/v1/geo/suggest',
          queryParameters: {'query': query},
        );
}
