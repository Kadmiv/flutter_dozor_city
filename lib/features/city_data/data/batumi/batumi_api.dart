import 'package:flutter_dozor_city/core/network/dio_client.dart';
import 'package:flutter_dozor_city/features/city_data/data/batumi/batumi_bus_location_dto.dart';
import 'package:flutter_dozor_city/features/city_data/data/batumi/batumi_db_data_dto.dart';
import 'package:flutter_dozor_city/features/city_data/data/batumi/batumi_points_between_stations_dto.dart';
import 'package:flutter_dozor_city/features/city_data/data/batumi/requests/get_batumi_bus_locs_on_route_request.dart';
import 'package:flutter_dozor_city/features/city_data/data/batumi/requests/get_batumi_db_data_request.dart';
import 'package:flutter_dozor_city/features/city_data/data/batumi/requests/get_batumi_points_between_stations_request.dart';

class BatumiApi {
  BatumiApi(this._dioClient);

  final DioClient _dioClient;

  Future<BatumiDbDataDto> getDbData(GetBatumiDbDataRequest request) async {
    final response = await _dioClient.request(request);
    return BatumiDbDataDto.fromApiResponse(response.data);
  }

  Future<BatumiPointsBetweenStationsDto> getPointsBetweenStations(
    GetBatumiPointsBetweenStationsRequest request,
  ) async {
    final response = await _dioClient.request(request);
    return BatumiPointsBetweenStationsDto.fromApiResponse(response.data);
  }

  Future<List<BatumiBusLocationDto>> getBusLocsOnRoute(
    GetBatumiBusLocsOnRouteRequest request,
  ) async {
    final response = await _dioClient.request(request);
    return BatumiBusLocationsResponseDto.fromApiResponse(response.data).locations;
  }
}
