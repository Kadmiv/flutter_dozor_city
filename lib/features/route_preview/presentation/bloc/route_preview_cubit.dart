import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_dozor_city/core/domain/entities/route_result.dart';
import 'package:flutter_dozor_city/core/domain/entities/search_params.dart';
import 'package:flutter_dozor_city/core/domain/entities/selected_point.dart';
import 'package:flutter_dozor_city/features/route_preview/domain/usecases/build_preview_camera_use_case.dart';
import 'package:flutter_dozor_city/core/map/app_map_camera.dart';

class RoutePreviewState {
  const RoutePreviewState({
    this.route,
    this.camera,
    this.start,
    this.end,
  });

  final RouteResult? route;
  final AppMapCamera? camera;
  final SelectedPoint? start;
  final SelectedPoint? end;

  RoutePreviewState copyWith({
    RouteResult? route,
    AppMapCamera? camera,
    SelectedPoint? start,
    SelectedPoint? end,
    bool clearRoute = false,
    bool clearCamera = false,
    bool clearPoints = false,
  }) {
    return RoutePreviewState(
      route: clearRoute ? null : route ?? this.route,
      camera: clearCamera ? null : camera ?? this.camera,
      start: clearPoints ? null : start ?? this.start,
      end: clearPoints ? null : end ?? this.end,
    );
  }
}

class RoutePreviewCubit extends Cubit<RoutePreviewState> {
  RoutePreviewCubit({
    BuildPreviewCameraUseCase buildPreviewCameraUseCase =
        const BuildPreviewCameraUseCase(),
  })  : _buildPreviewCameraUseCase = buildPreviewCameraUseCase,
        super(const RoutePreviewState());

  final BuildPreviewCameraUseCase _buildPreviewCameraUseCase;

  void show(
    RouteResult routeResult, {
    SearchParams? searchParams,
  }) {
    emit(
      state.copyWith(
        route: routeResult,
        camera: searchParams == null
            ? _reuseOrBuildCameraFromRoute(routeResult)
            : _buildPreviewCameraUseCase(searchParams),
        start: searchParams?.start ?? _pointFromRouteStart(routeResult),
        end: searchParams?.end ?? _pointFromRouteEnd(routeResult),
        clearPoints: false,
      ),
    );
  }

  void clear() {
    emit(
      state.copyWith(
        clearRoute: true,
        clearCamera: true,
        clearPoints: true,
      ),
    );
  }

  AppMapCamera? _reuseOrBuildCameraFromRoute(RouteResult routeResult) {
    final current = state.camera;
    if (current != null) {
      return current;
    }
    final start = routeResult.realStartPoint;
    final end = routeResult.realEndPoint;
    if (start == null || end == null) {
      return null;
    }
    return _buildPreviewCameraUseCase(
      SearchParams(
        start: SelectedPoint(
          label: routeResult.startName,
          lat: start.lat,
          lng: start.lng,
          source: SelectedPointSource.zone,
        ),
        end: SelectedPoint(
          label: routeResult.endName,
          lat: end.lat,
          lng: end.lng,
          source: SelectedPointSource.address,
        ),
        transportTypes: const {0},
      ),
    );
  }

  SelectedPoint? _pointFromRouteStart(RouteResult routeResult) {
    final point = routeResult.realStartPoint;
    if (point == null) {
      return null;
    }
    return SelectedPoint(
      label: routeResult.startName,
      lat: point.lat,
      lng: point.lng,
      source: SelectedPointSource.zone,
    );
  }

  SelectedPoint? _pointFromRouteEnd(RouteResult routeResult) {
    final point = routeResult.realEndPoint;
    if (point == null) {
      return null;
    }
    return SelectedPoint(
      label: routeResult.endName,
      lat: point.lat,
      lng: point.lng,
      source: SelectedPointSource.address,
    );
  }
}
