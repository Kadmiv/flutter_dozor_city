import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_dozor_city/core/domain/entities/app_lat_lng.dart';
import 'package:flutter_dozor_city/core/domain/entities/arrival_info.dart';
import 'package:flutter_dozor_city/core/domain/entities/city.dart';
import 'package:flutter_dozor_city/core/domain/entities/route_zone.dart';
import 'package:flutter_dozor_city/core/domain/entities/transport_route.dart';
import 'package:flutter_dozor_city/core/domain/entities/vehicle.dart';
import 'package:flutter_dozor_city/core/domain/repositories/city_repository.dart';
import 'package:flutter_dozor_city/features/main_map/domain/usecases/get_city_stops_use_case.dart';
import 'package:flutter_dozor_city/features/main_map/presentation/bloc/map_stops_cubit.dart';

class _FakeCityRepository implements CityRepository {
  @override
  Future<bool> ensureCityDataFresh(String cityId) async => true;

  @override
  Future<ArrivalInfo> getArrivalByZone({
    required String cityId,
    required String zoneId,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<List<City>> getCities() async => const [];

  @override
  Future<List<RouteZone>> getCityStops(String cityId) async => [
    const RouteZone(
      id: 'stop-1',
      routeId: 'route-1',
      name: 'Зупинка 1',
      position: AppLatLng(lat: 50.25, lng: 28.66),
    ),
  ];

  @override
  Future<List<Vehicle>> getCityVehicles(
    String cityId, {
    List<String>? routeIds,
  }) async => const [];

  @override
  Future<List<RouteZone>> getRouteZones(String routeId) async => const [];

  @override
  Future<List<TransportRoute>> getRoutesByType({
    required String cityId,
    required int transportType,
  }) async => const [];

  @override
  Future<void> preloadCityData(String cityId) async {}
}

void main() {
  test('loads and resets city stops', () async {
    final cubit = MapStopsCubit(
      getCityStopsUseCase: GetCityStopsUseCase(_FakeCityRepository()),
    );

    await cubit.loadForCity('zhytomyr');

    expect(cubit.state.activeCityId, 'zhytomyr');
    expect(cubit.state.cityStops, hasLength(1));
    expect(cubit.state.cityStops.first.position, isNotNull);

    cubit.reset();

    expect(cubit.state.cityStops, isEmpty);
    expect(cubit.state.activeCityId, isNull);
  });
}
