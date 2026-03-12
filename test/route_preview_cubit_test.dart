import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_dozor_city/core/domain/entities/app_lat_lng.dart';
import 'package:flutter_dozor_city/core/domain/entities/route_result.dart';
import 'package:flutter_dozor_city/core/domain/entities/search_params.dart';
import 'package:flutter_dozor_city/core/domain/entities/selected_point.dart';
import 'package:flutter_dozor_city/core/map/app_map_camera.dart';
import 'package:flutter_dozor_city/features/route_preview/domain/usecases/build_preview_camera_use_case.dart';
import 'package:flutter_dozor_city/features/route_preview/presentation/bloc/route_preview_cubit.dart';

void main() {
  group('RoutePreviewCubit', () {
    const route = RouteResult(
      id: 'preview-1',
      title: 'Маршрут preview',
      startName: 'Старт',
      endName: 'Фініш',
      walkToStartMeters: 100,
      walkToEndMeters: 200,
      transferSummary: 'Без пересадок',
    );
    const start = SelectedPoint(
      label: 'Майдан Соборний',
      lat: 50.254,
      lng: 28.658,
      source: SelectedPointSource.zone,
      zoneId: 101,
    );
    const end = SelectedPoint(
      label: 'Автовокзал',
      lat: 50.271,
      lng: 28.676,
      source: SelectedPointSource.address,
    );

    test('show with search params sets route, points and preview camera', () {
      final cubit = RoutePreviewCubit(
        buildPreviewCameraUseCase: const BuildPreviewCameraUseCase(),
      );

      cubit.show(
        route,
        searchParams: const SearchParams(
          start: start,
          end: end,
          transportTypes: {0},
        ),
      );

      expect(cubit.state.route, route);
      expect(cubit.state.start, start);
      expect(cubit.state.end, end);
      expect(
        cubit.state.camera,
        const AppMapCamera(
          centerLat: 50.2625,
          centerLng: 28.667,
          zoom: 14.0,
        ),
      );
    });

    test('show without search params keeps previous camera and preserves route points', () {
      final cubit = RoutePreviewCubit(
        buildPreviewCameraUseCase: const BuildPreviewCameraUseCase(),
      );
      cubit.show(
        route,
        searchParams: const SearchParams(
          start: start,
          end: end,
          transportTypes: {0},
        ),
      );

      final previousCamera = cubit.state.camera;
      final nextRoute = route.copyWith();

      cubit.show(nextRoute);

      expect(cubit.state.route, nextRoute);
      expect(cubit.state.camera, previousCamera);
      expect(cubit.state.start, start);
      expect(cubit.state.end, end);
    });

    test('show without search params uses route real points when available', () {
      final cubit = RoutePreviewCubit(
        buildPreviewCameraUseCase: const BuildPreviewCameraUseCase(),
      );
      const routeWithPoints = RouteResult(
        id: 'preview-2',
        title: 'Маршрут з точками',
        startName: 'Початок',
        endName: 'Кінець',
        walkToStartMeters: 50,
        walkToEndMeters: 70,
        transferSummary: 'Без пересадок',
        realStartPoint: AppLatLng(lat: 50.254, lng: 28.658),
        realEndPoint: AppLatLng(lat: 50.271, lng: 28.676),
      );

      cubit.show(routeWithPoints);

      expect(cubit.state.start, isNotNull);
      expect(cubit.state.end, isNotNull);
      expect(cubit.state.start!.label, 'Початок');
      expect(cubit.state.end!.label, 'Кінець');
      expect(cubit.state.camera, isNotNull);
    });

    test('clear removes route, camera and points', () {
      final cubit = RoutePreviewCubit(
        buildPreviewCameraUseCase: const BuildPreviewCameraUseCase(),
      );
      cubit.show(
        route,
        searchParams: const SearchParams(
          start: start,
          end: end,
          transportTypes: {0},
        ),
      );

      cubit.clear();

      expect(cubit.state.route, isNull);
      expect(cubit.state.camera, isNull);
      expect(cubit.state.start, isNull);
      expect(cubit.state.end, isNull);
    });
  });
}
