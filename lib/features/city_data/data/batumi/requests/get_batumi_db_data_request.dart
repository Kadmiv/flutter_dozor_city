import 'package:flutter_dozor_city/core/network/request/app_request.dart';
import 'package:flutter_dozor_city/features/city_data/data/batumi/batumi_api_paths.dart';

class GetBatumiDbDataRequest extends AppRequest {
  const GetBatumiDbDataRequest()
      : super(
          method: AppRequestMethod.get,
          path: BatumiApiPaths.getDbData,
          baseUrl: BatumiApiPaths.baseUrl,
        );
}
