import 'package:flutter_dozor_city/core/network/request/app_request.dart';
import 'package:flutter_dozor_city/features/city_data/data/batumi/batumi_api_paths.dart';

class GetBatumiLiveDataRequest extends AppRequest {
  GetBatumiLiveDataRequest({required String routeId})
    : super(
        method: AppRequestMethod.get,
        path: BatumiApiPaths.getLiveData,
        baseUrl: BatumiApiPaths.baseUrl,
        queryParameters: {'routeId': routeId},
      );
}
