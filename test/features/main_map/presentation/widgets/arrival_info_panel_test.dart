import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_dozor_city/core/domain/entities/arrival_info.dart';
import 'package:flutter_dozor_city/core/domain/entities/transport_route.dart';
import 'package:flutter_dozor_city/core/domain/entities/route_arrival.dart';
import 'package:flutter_dozor_city/core/domain/entities/route_zone.dart';
import 'package:flutter_dozor_city/core/domain/entities/app_lat_lng.dart';
import 'package:flutter_dozor_city/core/domain/entities/city.dart';
import 'package:flutter_dozor_city/core/domain/repositories/city_repository.dart';
import 'package:flutter_dozor_city/core/domain/entities/vehicle.dart';
import 'package:flutter_dozor_city/features/main_map/domain/usecases/get_arrival_by_zone_use_case.dart';
import 'package:flutter_dozor_city/features/main_map/domain/usecases/get_route_zones_use_case.dart';
import 'package:flutter_dozor_city/features/main_map/presentation/bloc/map_arrivals_cubit.dart';
import 'package:flutter_dozor_city/features/main_map/presentation/widgets/map_overlays/arrival_info_panel.dart';
import '../../../../helpers/fake_polling_scheduler.dart';

class _FakeCityRepository implements CityRepository {
  _FakeCityRepository({required this.arrival});

  final ArrivalInfo arrival;

  @override
  Future<bool> ensureCityDataFresh(String cityId) async => true;

  @override
  Future<ArrivalInfo> getArrivalByZone({
    required String cityId,
    required String zoneId,
  }) async => arrival;

  @override
  Future<List<City>> getCities() async => const [];

  @override
  Future<List<RouteZone>> getRouteZones(String routeId) async => const [];

  @override
  Future<List<RouteZone>> getCityStops(String cityId) async => const [
    RouteZone(
      id: 'stop-1',
      routeId: 'route-1',
      name: 'Зупинка 1',
      position: AppLatLng(lat: 50.25, lng: 28.66),
    ),
  ];

  @override
  Future<List<TransportRoute>> getRoutesByType({
    required String cityId,
    required int transportType,
  }) async => const [];

  @override
  Future<List<Vehicle>> getCityVehicles(
    String cityId, {
    List<String>? routeIds,
  }) async => const [];

  @override
  Future<void> preloadCityData(String cityId) async {}
}

void main() {
  testWidgets('shows rich route arrivals when available', (tester) async {
    final repository = _FakeCityRepository(
      arrival: const ArrivalInfo(
        zoneId: 'stop-1',
        busMinutes: [1, 2, 12, 13],
        trolleyMinutes: [],
        tramMinutes: [],
        routeArrivals: [
          RouteArrival(
            routeId: 'route-1',
            routeShortName: '10',
            busId: 'bus-1',
            busName: 'TT 683 ET',
            minute: 2,
          ),
          RouteArrival(
            routeId: 'route-2',
            routeShortName: '12',
            busId: 'bus-2',
            busName: 'TT 689 ET',
            minute: 13,
          ),
        ],
      ),
    );
    final cubit = MapArrivalsBloc(
      getRouteZonesUseCase: GetRouteZonesUseCase(repository),
      getArrivalByZoneUseCase: GetArrivalByZoneUseCase(repository),
      pollingScheduler: FakePollingScheduler(),
    );

    await cubit.loadArrival(cityId: 'batumi', zoneId: 'stop-1');

    await tester.pumpWidget(
      MaterialApp(
        home: BlocProvider.value(
          value: cubit,
          child: const Scaffold(body: ArrivalInfoPanel()),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Прибуття транспорту'), findsOneWidget);
    expect(find.text('10'), findsOneWidget);
    expect(find.text('2 хв'), findsOneWidget);
    expect(find.text('TT 683 ET'), findsOneWidget);
    expect(find.text('12'), findsOneWidget);
    expect(find.text('13 хв'), findsOneWidget);
    expect(find.text('TT 689 ET'), findsOneWidget);
  });

  testWidgets('falls back to minutes table when no rich arrivals exist', (
    tester,
  ) async {
    final repository = _FakeCityRepository(
      arrival: const ArrivalInfo(
        zoneId: 'stop-1',
        busMinutes: [3, 8],
        trolleyMinutes: [5],
        tramMinutes: [],
      ),
    );
    final cubit = MapArrivalsBloc(
      getRouteZonesUseCase: GetRouteZonesUseCase(repository),
      getArrivalByZoneUseCase: GetArrivalByZoneUseCase(repository),
      pollingScheduler: FakePollingScheduler(),
    );

    await cubit.loadArrival(cityId: 'batumi', zoneId: 'stop-1');

    await tester.pumpWidget(
      MaterialApp(
        home: BlocProvider.value(
          value: cubit,
          child: const Scaffold(body: ArrivalInfoPanel()),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Автобус'), findsOneWidget);
    expect(find.text('3, 8'), findsOneWidget);
    expect(find.text('Тролейбус'), findsOneWidget);
    expect(find.text('5'), findsOneWidget);
  });
}
