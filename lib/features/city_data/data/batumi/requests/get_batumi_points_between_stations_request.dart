import 'package:flutter_dozor_city/core/network/request/app_request.dart';
import 'package:flutter_dozor_city/features/city_data/data/batumi/batumi_api_paths.dart';

class GetBatumiPointsBetweenStationsRequest extends AppRequest {
  const GetBatumiPointsBetweenStationsRequest()
      : super(
          method: AppRequestMethod.get,
          path: BatumiApiPaths.getPointsBetweenStations,
          baseUrl: BatumiApiPaths.baseUrl,
        );
}
