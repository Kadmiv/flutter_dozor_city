import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_dozor_city/core/domain/entities/app_lat_lng.dart';
import 'package:flutter_dozor_city/core/domain/entities/route_result.dart';
import 'package:flutter_dozor_city/core/domain/entities/search_params.dart';
import 'package:flutter_dozor_city/core/domain/entities/selected_point.dart';
import 'package:flutter_dozor_city/core/error/failures.dart';
import 'package:flutter_dozor_city/features/route_preview/presentation/bloc/route_preview_cubit.dart';
import 'package:flutter_dozor_city/features/route_results/domain/usecases/search_routes_use_case.dart';

enum MapRoutePlanningMode { inactive, selectingStart, selectingEnd, previewing }

class MapRoutePlanningState {
  const MapRoutePlanningState({
    this.mode = MapRoutePlanningMode.inactive,
    this.start,
    this.end,
    this.transportTypes = const {0},
    this.results = const [],
    this.activeResult,
    this.isLoading = false,
    this.failure,
  });

  final MapRoutePlanningMode mode;
  final SelectedPoint? start;
  final SelectedPoint? end;
  final Set<int> transportTypes;
  final List<RouteResult> results;
  final RouteResult? activeResult;
  final bool isLoading;
  final AppFailure? failure;

  SearchParams? get params {
    if (start == null || end == null || transportTypes.isEmpty) {
      return null;
    }
    return SearchParams(
      start: start!,
      end: end!,
      transportTypes: transportTypes,
    );
  }

  MapRoutePlanningState copyWith({
    MapRoutePlanningMode? mode,
    SelectedPoint? start,
    SelectedPoint? end,
    Set<int>? transportTypes,
    List<RouteResult>? results,
    RouteResult? activeResult,
    bool? isLoading,
    AppFailure? failure,
    bool clearFailure = false,
  }) {
    return MapRoutePlanningState(
      mode: mode ?? this.mode,
      start: start ?? this.start,
      end: end ?? this.end,
      transportTypes: transportTypes ?? this.transportTypes,
      results: results ?? this.results,
      activeResult: activeResult ?? this.activeResult,
      isLoading: isLoading ?? this.isLoading,
      failure: clearFailure ? null : (failure ?? this.failure),
    );
  }
}

class MapRoutePlanningCubit extends Cubit<MapRoutePlanningState> {
  MapRoutePlanningCubit({
    required SearchRoutesUseCase searchRoutesUseCase,
    required RoutePreviewCubit routePreviewCubit,
  }) : _searchRoutesUseCase = searchRoutesUseCase,
       _routePreviewCubit = routePreviewCubit,
       super(const MapRoutePlanningState());

  final SearchRoutesUseCase _searchRoutesUseCase;
  final RoutePreviewCubit _routePreviewCubit;

  void startPlanning() {
    emit(
      state.copyWith(
        mode: MapRoutePlanningMode.selectingStart,
        clearFailure: true,
      ),
    );
    _routePreviewCubit.clear();
  }

  void startSelectingStart() {
    emit(
      state.copyWith(
        mode: MapRoutePlanningMode.selectingStart,
        clearFailure: true,
      ),
    );
  }

  void startSelectingEnd() {
    emit(
      state.copyWith(
        mode: MapRoutePlanningMode.selectingEnd,
        clearFailure: true,
      ),
    );
  }

  void cancel() {
    emit(
      state.copyWith(mode: MapRoutePlanningMode.inactive, clearFailure: true),
    );
    _routePreviewCubit.clear();
  }

  void toggleTransportType(int type) {
    final next = Set<int>.from(state.transportTypes);
    if (!next.add(type)) {
      next.remove(type);
    }
    emit(state.copyWith(transportTypes: next));
  }

  void setPointFromMap(AppLatLng point) {
    final selectedPoint = SelectedPoint(
      label: 'Точка на мапі',
      lat: point.lat,
      lng: point.lng,
      source: SelectedPointSource.mapTap,
    );
    switch (state.mode) {
      case MapRoutePlanningMode.selectingStart:
        emit(
          state.copyWith(
            start: selectedPoint,
            mode: MapRoutePlanningMode.selectingEnd,
          ),
        );
        break;
      case MapRoutePlanningMode.selectingEnd:
        emit(
          state.copyWith(
            end: selectedPoint,
            mode: MapRoutePlanningMode.previewing,
          ),
        );
        break;
      case MapRoutePlanningMode.previewing:
      case MapRoutePlanningMode.inactive:
        return;
    }
    if (state.start != null && state.end != null) {
      search();
    }
  }

  void setStart(SelectedPoint point) {
    emit(
      state.copyWith(
        start: point,
        mode: MapRoutePlanningMode.selectingEnd,
        clearFailure: true,
      ),
    );
    if (state.end != null) {
      search();
    }
  }

  void setEnd(SelectedPoint point) {
    emit(
      state.copyWith(
        end: point,
        mode: MapRoutePlanningMode.previewing,
        clearFailure: true,
      ),
    );
    if (state.start != null) {
      search();
    }
  }

  void swap() {
    emit(
      state.copyWith(
        start: state.end,
        end: state.start,
        mode: MapRoutePlanningMode.previewing,
        clearFailure: true,
      ),
    );
    if (state.start != null && state.end != null) {
      search();
    }
  }

  Future<void> search() async {
    final params = state.params;
    if (params == null) {
      return;
    }
    emit(state.copyWith(isLoading: true, clearFailure: true));
    try {
      final results = await _searchRoutesUseCase(params);
      final activeResult = results.isNotEmpty ? results.first : null;
      emit(
        state.copyWith(
          mode: MapRoutePlanningMode.previewing,
          results: results,
          activeResult: activeResult,
          isLoading: false,
        ),
      );
      if (activeResult != null) {
        _routePreviewCubit.show(activeResult, searchParams: params);
      } else {
        _routePreviewCubit.clear();
      }
    } on AppFailure catch (e) {
      emit(state.copyWith(isLoading: false, failure: e));
    } catch (e) {
      emit(
        state.copyWith(isLoading: false, failure: ParseFailure(e.toString())),
      );
    }
  }

  void selectResult(RouteResult result) {
    final params = state.params;
    emit(
      state.copyWith(
        activeResult: result,
        mode: MapRoutePlanningMode.previewing,
      ),
    );
    if (params != null) {
      _routePreviewCubit.show(result, searchParams: params);
    }
  }

  void clear() {
    emit(const MapRoutePlanningState());
    _routePreviewCubit.clear();
  }
}
