import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_dozor_city/core/domain/entities/app_lat_lng.dart';
import 'package:flutter_dozor_city/core/domain/entities/route_result.dart';
import 'package:flutter_dozor_city/core/domain/entities/search_params.dart';
import 'package:flutter_dozor_city/core/domain/entities/selected_point.dart';
import 'package:flutter_dozor_city/core/error/failures.dart';
import 'package:flutter_dozor_city/features/route_preview/presentation/bloc/route_preview_cubit.dart';
import 'package:flutter_dozor_city/features/route_results/domain/usecases/search_routes_use_case.dart';

enum MapRoutePlanningMode { inactive, selectingStart, selectingEnd, previewing }

sealed class MapRoutePlanningEvent extends Equatable {
  const MapRoutePlanningEvent();

  @override
  List<Object?> get props => const [];
}

final class MapRoutePlanningStarted extends MapRoutePlanningEvent {
  const MapRoutePlanningStarted();
}

final class MapRoutePlanningStartSelectingStart extends MapRoutePlanningEvent {
  const MapRoutePlanningStartSelectingStart();
}

final class MapRoutePlanningStartSelectingEnd extends MapRoutePlanningEvent {
  const MapRoutePlanningStartSelectingEnd();
}

final class MapRoutePlanningCancelled extends MapRoutePlanningEvent {
  const MapRoutePlanningCancelled();
}

final class MapRoutePlanningTransportTypeToggled extends MapRoutePlanningEvent {
  const MapRoutePlanningTransportTypeToggled(this.type);

  final int type;

  @override
  List<Object?> get props => [type];
}

final class MapRoutePlanningPointFromMapSet extends MapRoutePlanningEvent {
  const MapRoutePlanningPointFromMapSet(this.point);

  final AppLatLng point;

  @override
  List<Object?> get props => [point];
}

final class MapRoutePlanningStartFromMapChanged extends MapRoutePlanningEvent {
  const MapRoutePlanningStartFromMapChanged(
    this.point, {
    this.commitSearch = false,
  });

  final AppLatLng point;
  final bool commitSearch;

  @override
  List<Object?> get props => [point, commitSearch];
}

final class MapRoutePlanningEndFromMapChanged extends MapRoutePlanningEvent {
  const MapRoutePlanningEndFromMapChanged(
    this.point, {
    this.commitSearch = false,
  });

  final AppLatLng point;
  final bool commitSearch;

  @override
  List<Object?> get props => [point, commitSearch];
}

final class MapRoutePlanningStartSet extends MapRoutePlanningEvent {
  const MapRoutePlanningStartSet(this.point);

  final SelectedPoint point;

  @override
  List<Object?> get props => [point];
}

final class MapRoutePlanningEndSet extends MapRoutePlanningEvent {
  const MapRoutePlanningEndSet(this.point);

  final SelectedPoint point;

  @override
  List<Object?> get props => [point];
}

final class MapRoutePlanningSwapped extends MapRoutePlanningEvent {
  const MapRoutePlanningSwapped();
}

final class MapRoutePlanningSearchRequested extends MapRoutePlanningEvent {
  const MapRoutePlanningSearchRequested();
}

final class MapRoutePlanningResultSelected extends MapRoutePlanningEvent {
  const MapRoutePlanningResultSelected(this.result);

  final RouteResult result;

  @override
  List<Object?> get props => [result];
}

final class MapRoutePlanningCleared extends MapRoutePlanningEvent {
  const MapRoutePlanningCleared();
}

class MapRoutePlanningState extends Equatable {
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

  @override
  List<Object?> get props => [
    mode,
    start,
    end,
    transportTypes,
    results,
    activeResult,
    isLoading,
    failure,
  ];
}

class MapRoutePlanningBloc
    extends Bloc<MapRoutePlanningEvent, MapRoutePlanningState> {
  MapRoutePlanningBloc({
    required SearchRoutesUseCase searchRoutesUseCase,
    required RoutePreviewBloc routePreviewBloc,
  }) : _searchRoutesUseCase = searchRoutesUseCase,
       _routePreviewBloc = routePreviewBloc,
       super(const MapRoutePlanningState()) {
    on<MapRoutePlanningStarted>(_onStarted);
    on<MapRoutePlanningStartSelectingStart>(_onStartSelectingStart);
    on<MapRoutePlanningStartSelectingEnd>(_onStartSelectingEnd);
    on<MapRoutePlanningCancelled>(_onCancelled);
    on<MapRoutePlanningTransportTypeToggled>(_onTransportTypeToggled);
    on<MapRoutePlanningPointFromMapSet>(_onPointFromMapSet);
    on<MapRoutePlanningStartFromMapChanged>(_onStartFromMapChanged);
    on<MapRoutePlanningEndFromMapChanged>(_onEndFromMapChanged);
    on<MapRoutePlanningStartSet>(_onStartSet);
    on<MapRoutePlanningEndSet>(_onEndSet);
    on<MapRoutePlanningSwapped>(_onSwapped);
    on<MapRoutePlanningSearchRequested>(_onSearchRequested);
    on<MapRoutePlanningResultSelected>(_onResultSelected);
    on<MapRoutePlanningCleared>(_onCleared);
  }

  final SearchRoutesUseCase _searchRoutesUseCase;
  final RoutePreviewBloc _routePreviewBloc;

  void startPlanning() => add(const MapRoutePlanningStarted());
  void startSelectingStart() =>
      add(const MapRoutePlanningStartSelectingStart());
  void startSelectingEnd() => add(const MapRoutePlanningStartSelectingEnd());
  void cancel() => add(const MapRoutePlanningCancelled());
  void toggleTransportType(int type) =>
      add(MapRoutePlanningTransportTypeToggled(type));
  void setPointFromMap(AppLatLng point) =>
      add(MapRoutePlanningPointFromMapSet(point));
  void setStartFromMap(AppLatLng point, {bool commitSearch = false}) => add(
    MapRoutePlanningStartFromMapChanged(point, commitSearch: commitSearch),
  );
  void setEndFromMap(AppLatLng point, {bool commitSearch = false}) =>
      add(MapRoutePlanningEndFromMapChanged(point, commitSearch: commitSearch));
  void setStart(SelectedPoint point) => add(MapRoutePlanningStartSet(point));
  void setEnd(SelectedPoint point) => add(MapRoutePlanningEndSet(point));
  void swap() => add(const MapRoutePlanningSwapped());
  void search() => add(const MapRoutePlanningSearchRequested());
  void selectResult(RouteResult result) =>
      add(MapRoutePlanningResultSelected(result));
  void clear() => add(const MapRoutePlanningCleared());

  Future<void> _onStarted(
    MapRoutePlanningStarted event,
    Emitter<MapRoutePlanningState> emit,
  ) async {
    emit(
      state.copyWith(
        mode: MapRoutePlanningMode.selectingStart,
        results: const [],
        activeResult: null,
        isLoading: false,
        clearFailure: true,
      ),
    );
    _routePreviewBloc.add(const RoutePreviewCleared());
  }

  Future<void> _onStartSelectingStart(
    MapRoutePlanningStartSelectingStart event,
    Emitter<MapRoutePlanningState> emit,
  ) async {
    emit(
      state.copyWith(
        mode: MapRoutePlanningMode.selectingStart,
        clearFailure: true,
      ),
    );
  }

  Future<void> _onStartSelectingEnd(
    MapRoutePlanningStartSelectingEnd event,
    Emitter<MapRoutePlanningState> emit,
  ) async {
    emit(
      state.copyWith(
        mode: MapRoutePlanningMode.selectingEnd,
        clearFailure: true,
      ),
    );
  }

  void _onCancelled(
    MapRoutePlanningCancelled event,
    Emitter<MapRoutePlanningState> emit,
  ) {
    emit(const MapRoutePlanningState());
    _routePreviewBloc.add(const RoutePreviewCleared());
  }

  void _onTransportTypeToggled(
    MapRoutePlanningTransportTypeToggled event,
    Emitter<MapRoutePlanningState> emit,
  ) {
    final next = Set<int>.from(state.transportTypes);
    if (!next.add(event.type)) {
      next.remove(event.type);
    }
    emit(state.copyWith(transportTypes: next));
  }

  void _onPointFromMapSet(
    MapRoutePlanningPointFromMapSet event,
    Emitter<MapRoutePlanningState> emit,
  ) {
    switch (state.mode) {
      case MapRoutePlanningMode.selectingStart:
        final startPoint = SelectedPoint(
          label: 'Точка на мапі',
          lat: event.point.lat,
          lng: event.point.lng,
          source: SelectedPointSource.mapTap,
        );
        emit(
          state.copyWith(
            start: startPoint,
            mode: MapRoutePlanningMode.selectingEnd,
          ),
        );
        break;
      case MapRoutePlanningMode.selectingEnd:
        final endPoint = SelectedPoint(
          label: 'Точка на мапі',
          lat: event.point.lat,
          lng: event.point.lng,
          source: SelectedPointSource.mapTap,
        );
        emit(
          state.copyWith(end: endPoint, mode: MapRoutePlanningMode.previewing),
        );
        break;
      case MapRoutePlanningMode.previewing:
      case MapRoutePlanningMode.inactive:
        return;
    }
    if (state.start != null && state.end != null) {
      add(const MapRoutePlanningSearchRequested());
    }
  }

  void _onStartFromMapChanged(
    MapRoutePlanningStartFromMapChanged event,
    Emitter<MapRoutePlanningState> emit,
  ) {
    emit(
      state.copyWith(
        start: SelectedPoint(
          label: 'Точка на мапі',
          lat: event.point.lat,
          lng: event.point.lng,
          source: SelectedPointSource.mapTap,
        ),
      ),
    );
    if (event.commitSearch && state.end != null) {
      add(const MapRoutePlanningSearchRequested());
    }
  }

  void _onEndFromMapChanged(
    MapRoutePlanningEndFromMapChanged event,
    Emitter<MapRoutePlanningState> emit,
  ) {
    emit(
      state.copyWith(
        end: SelectedPoint(
          label: 'Точка на мапі',
          lat: event.point.lat,
          lng: event.point.lng,
          source: SelectedPointSource.mapTap,
        ),
      ),
    );
    if (event.commitSearch && state.start != null) {
      add(const MapRoutePlanningSearchRequested());
    }
  }

  void _onStartSet(
    MapRoutePlanningStartSet event,
    Emitter<MapRoutePlanningState> emit,
  ) {
    emit(
      state.copyWith(
        start: event.point,
        mode: MapRoutePlanningMode.selectingEnd,
        clearFailure: true,
      ),
    );
    if (state.end != null) {
      add(const MapRoutePlanningSearchRequested());
    }
  }

  void _onEndSet(
    MapRoutePlanningEndSet event,
    Emitter<MapRoutePlanningState> emit,
  ) {
    emit(
      state.copyWith(
        end: event.point,
        mode: MapRoutePlanningMode.previewing,
        clearFailure: true,
      ),
    );
    if (state.start != null) {
      add(const MapRoutePlanningSearchRequested());
    }
  }

  void _onSwapped(
    MapRoutePlanningSwapped event,
    Emitter<MapRoutePlanningState> emit,
  ) {
    emit(
      state.copyWith(
        start: state.end,
        end: state.start,
        mode: MapRoutePlanningMode.previewing,
        clearFailure: true,
      ),
    );
    if (state.start != null && state.end != null) {
      add(const MapRoutePlanningSearchRequested());
    }
  }

  Future<void> _onSearchRequested(
    MapRoutePlanningSearchRequested event,
    Emitter<MapRoutePlanningState> emit,
  ) async {
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
        _routePreviewBloc.add(
          RoutePreviewShown(activeResult, searchParams: params),
        );
      } else {
        _routePreviewBloc.add(const RoutePreviewCleared());
      }
    } on AppFailure catch (e) {
      emit(state.copyWith(isLoading: false, failure: e));
    } catch (e) {
      emit(
        state.copyWith(isLoading: false, failure: ParseFailure(e.toString())),
      );
    }
  }

  void _onResultSelected(
    MapRoutePlanningResultSelected event,
    Emitter<MapRoutePlanningState> emit,
  ) {
    final params = state.params;
    emit(
      state.copyWith(
        activeResult: event.result,
        mode: MapRoutePlanningMode.previewing,
      ),
    );
    if (params != null) {
      _routePreviewBloc.add(
        RoutePreviewShown(event.result, searchParams: params),
      );
    }
  }

  void _onCleared(
    MapRoutePlanningCleared event,
    Emitter<MapRoutePlanningState> emit,
  ) {
    emit(const MapRoutePlanningState());
    _routePreviewBloc.add(const RoutePreviewCleared());
  }
}
