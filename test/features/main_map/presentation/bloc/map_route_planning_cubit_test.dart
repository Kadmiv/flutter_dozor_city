import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_dozor_city/core/domain/entities/app_lat_lng.dart';
import 'package:flutter_dozor_city/core/domain/entities/route_result.dart';
import 'package:flutter_dozor_city/core/domain/entities/search_params.dart';
import 'package:flutter_dozor_city/core/domain/entities/selected_point.dart';
import 'package:flutter_dozor_city/core/domain/repositories/search_repository.dart';
import 'package:flutter_dozor_city/features/main_map/presentation/bloc/map_route_planning_cubit.dart';
import 'package:flutter_dozor_city/features/route_preview/presentation/bloc/route_preview_cubit.dart';
import 'package:flutter_dozor_city/features/route_results/domain/usecases/search_routes_use_case.dart';

class _FakeSearchRepository implements SearchRepository {
  int callCount = 0;
  SearchParams? lastParams;

  @override
  Future<SelectedPoint> getCurrentLocation() {
    throw UnimplementedError();
  }

  @override
  Future<List<SelectedPoint>> searchAddressSuggestions(String query) {
    throw UnimplementedError();
  }

  @override
  Future<List<RouteResult>> searchRoutes(SearchParams params) async {
    callCount += 1;
    lastParams = params;
    return const [
      RouteResult(
        id: 'route-1',
        title: 'Маршрут 1',
        startName: 'Старт',
        endName: 'Фініш',
        walkToStartMeters: 120,
        walkToEndMeters: 80,
        transferSummary: 'Без пересадок',
        totalTravelMinutes: 18,
      ),
    ];
  }
}

void main() {
  group('MapRoutePlanningBloc', () {
    const start = SelectedPoint(
      label: 'Початок',
      lat: 50.250,
      lng: 28.660,
      source: SelectedPointSource.address,
    );
    const end = SelectedPoint(
      label: 'Кінець',
      lat: 50.260,
      lng: 28.670,
      source: SelectedPointSource.zone,
      zoneId: 77,
    );

    test('setStartFromMap and setEndFromMap keep map point labels', () async {
      final repository = _FakeSearchRepository();
      final routePreviewBloc = RoutePreviewBloc();
      final bloc = MapRoutePlanningBloc(
        searchRoutesUseCase: SearchRoutesUseCase(repository),
        routePreviewBloc: routePreviewBloc,
      );

      bloc.startPlanning();
      bloc.setStartFromMap(const AppLatLng(lat: 50.1, lng: 28.2));
      bloc.setEndFromMap(const AppLatLng(lat: 50.2, lng: 28.3));
      await Future<void>.delayed(Duration.zero);

      expect(bloc.state.start?.label, 'Точка на мапі');
      expect(bloc.state.end?.label, 'Точка на мапі');
      expect(bloc.state.mode, MapRoutePlanningMode.selectingStart);
      expect(repository.callCount, 0);
      expect(routePreviewBloc.state.route, isNull);
    });

    test('search runs when both points are set', () async {
      final repository = _FakeSearchRepository();
      final routePreviewBloc = RoutePreviewBloc();
      final bloc = MapRoutePlanningBloc(
        searchRoutesUseCase: SearchRoutesUseCase(repository),
        routePreviewBloc: routePreviewBloc,
      );

      bloc.startPlanning();
      bloc.setStart(start);
      bloc.setEnd(end);
      await Future<void>.delayed(Duration.zero);

      expect(repository.callCount, 1);
      expect(repository.lastParams, isNotNull);
      expect(bloc.state.mode, MapRoutePlanningMode.previewing);
      expect(bloc.state.results, hasLength(1));
      expect(bloc.state.activeResult?.id, 'route-1');
      expect(routePreviewBloc.state.route?.id, 'route-1');
      expect(routePreviewBloc.state.start, start);
      expect(routePreviewBloc.state.end, end);
    });

    test('swap exchanges points and reruns search', () async {
      final repository = _FakeSearchRepository();
      final routePreviewBloc = RoutePreviewBloc();
      final bloc = MapRoutePlanningBloc(
        searchRoutesUseCase: SearchRoutesUseCase(repository),
        routePreviewBloc: routePreviewBloc,
      );

      bloc.startPlanning();
      bloc.setStart(start);
      bloc.setEnd(end);
      await Future<void>.delayed(Duration.zero);

      repository.callCount = 0;
      bloc.swap();
      await Future<void>.delayed(Duration.zero);

      expect(bloc.state.start, end);
      expect(bloc.state.end, start);
      expect(repository.callCount, 1);
      expect(routePreviewBloc.state.start, end);
      expect(routePreviewBloc.state.end, start);
    });

    test('clear resets state and preview', () async {
      final repository = _FakeSearchRepository();
      final routePreviewBloc = RoutePreviewBloc();
      final bloc = MapRoutePlanningBloc(
        searchRoutesUseCase: SearchRoutesUseCase(repository),
        routePreviewBloc: routePreviewBloc,
      );

      bloc.startPlanning();
      bloc.setStart(start);
      bloc.setEnd(end);
      await Future<void>.delayed(Duration.zero);

      bloc.clear();
      await Future<void>.delayed(Duration.zero);

      expect(bloc.state, const MapRoutePlanningState());
      expect(routePreviewBloc.state.route, isNull);
      expect(routePreviewBloc.state.start, isNull);
      expect(routePreviewBloc.state.end, isNull);
    });
  });
}
