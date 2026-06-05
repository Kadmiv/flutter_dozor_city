import 'package:flutter_dozor_city/core/network/request/app_request.dart';
import 'package:flutter_dozor_city/features/city_data/data/batumi/batumi_api_paths.dart';

class GetBatumiBusLocsOnRouteRequest extends AppRequest {
  GetBatumiBusLocsOnRouteRequest({required String routeId})
      : super(
          method: AppRequestMethod.get,
          path: BatumiApiPaths.getBusLocsOnRoute,
          baseUrl: BatumiApiPaths.baseUrl,
          queryParameters: {'routeId': routeId},
        );
}
