import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_dozor_city/core/domain/entities/route_result.dart';
import 'package:flutter_dozor_city/core/domain/entities/search_params.dart';
import 'package:flutter_dozor_city/features/route_results/domain/usecases/search_routes_use_case.dart';
import 'package:flutter_dozor_city/features/route_results/domain/usecases/toggle_stored_route_use_case.dart';
import 'package:flutter_dozor_city/features/stored_routes/domain/usecases/get_stored_routes_use_case.dart';
import 'package:flutter_dozor_city/features/stored_routes/domain/usecases/watch_stored_routes_use_case.dart';

import 'package:flutter_dozor_city/core/error/failures.dart';

sealed class RouteResultsEvent extends Equatable {
  const RouteResultsEvent();

  @override
  List<Object?> get props => const [];
}

final class RouteResultsRequested extends RouteResultsEvent {
  const RouteResultsRequested(this.params);

  final SearchParams? params;

  @override
  List<Object?> get props => [params];
}

final class RouteResultsStoredRoutesChanged extends RouteResultsEvent {
  const RouteResultsStoredRoutesChanged();
}

final class RouteResultsToggleStoredRequested extends RouteResultsEvent {
  const RouteResultsToggleStoredRequested(this.result);

  final RouteResult result;

  @override
  List<Object?> get props => [result];
}

class RouteResultsState extends Equatable {
  const RouteResultsState({
    this.isLoading = false,
    this.results = const [],
    this.params,
    this.failure,
  });

  final bool isLoading;
  final List<RouteResult> results;
  final SearchParams? params;
  final AppFailure? failure;

  RouteResultsState copyWith({
    bool? isLoading,
    List<RouteResult>? results,
    SearchParams? params,
    AppFailure? failure,
    bool clearFailure = false,
  }) {
    return RouteResultsState(
      isLoading: isLoading ?? this.isLoading,
      results: results ?? this.results,
      params: params ?? this.params,
      failure: clearFailure ? null : (failure ?? this.failure),
    );
  }

  @override
  List<Object?> get props => [isLoading, results, params, failure];
}

class RouteResultsBloc extends Bloc<RouteResultsEvent, RouteResultsState> {
  RouteResultsBloc({
    required SearchRoutesUseCase searchRoutesUseCase,
    required GetStoredRoutesUseCase getStoredRoutesUseCase,
    required WatchStoredRoutesUseCase watchStoredRoutesUseCase,
    required ToggleStoredRouteUseCase toggleStoredRouteUseCase,
  })  : _searchRoutesUseCase = searchRoutesUseCase,
        _getStoredRoutesUseCase = getStoredRoutesUseCase,
        _watchStoredRoutesUseCase = watchStoredRoutesUseCase,
        _toggleStoredRouteUseCase = toggleStoredRouteUseCase,
        super(const RouteResultsState()) {
    _watchStoredRoutesUseCase.addListener(_handleStoredRoutesChanged);
    on<RouteResultsRequested>(_onRequested);
    on<RouteResultsStoredRoutesChanged>(_onStoredRoutesChanged);
    on<RouteResultsToggleStoredRequested>(_onToggleStoredRequested);
  }

  final SearchRoutesUseCase _searchRoutesUseCase;
  final GetStoredRoutesUseCase _getStoredRoutesUseCase;
  final WatchStoredRoutesUseCase _watchStoredRoutesUseCase;
  final ToggleStoredRouteUseCase _toggleStoredRouteUseCase;
  int _requestVersion = 0;

  Future<void> load(SearchParams? params) async {
    add(RouteResultsRequested(params));
  }

  Future<void> toggleStored(RouteResult result) async {
    add(RouteResultsToggleStoredRequested(result));
  }

  Future<void> _onRequested(
    RouteResultsRequested event,
    Emitter<RouteResultsState> emit,
  ) async {
    final params = event.params ?? state.params;
    if (params == null) {
      emit(state.copyWith(results: const [], clearFailure: true));
      return;
    }

    final requestId = ++_requestVersion;
    emit(state.copyWith(isLoading: true, params: params, clearFailure: true));
    try {
      final results = await _searchRoutesUseCase(params);
      final storedRoutes = await _getStoredRoutesUseCase();
      final storedIds = storedRoutes.map((route) => route.id).toSet();
      final normalized = <RouteResult>[];
      for (final result in results) {
          normalized.add(result.copyWith(isStored: storedIds.contains(result.id)));
      }
      if (requestId != _requestVersion || isClosed) {
        return;
      }
      emit(state.copyWith(isLoading: false, results: normalized, params: params));
    } on AppFailure catch (e) {
      if (requestId != _requestVersion || isClosed) {
        return;
      }
      emit(state.copyWith(isLoading: false, failure: e));
    } catch (e) {
      if (requestId != _requestVersion || isClosed) {
        return;
      }
      emit(state.copyWith(isLoading: false, failure: ParseFailure(e.toString())));
    }
  }

  Future<void> _onToggleStoredRequested(
    RouteResultsToggleStoredRequested event,
    Emitter<RouteResultsState> emit,
  ) async {
    final result = event.result;
    final isStored = await _toggleStoredRouteUseCase(result);
    final updated = state.results
        .map(
          (item) => item.id == result.id
              ? item.copyWith(isStored: isStored)
              : item,
        )
        .toList(growable: false);
    emit(state.copyWith(results: updated));
  }

  Future<void> _onStoredRoutesChanged(
    RouteResultsStoredRoutesChanged event,
    Emitter<RouteResultsState> emit,
  ) async {
    if (state.results.isEmpty) {
      return;
    }
    final storedRoutes = await _getStoredRoutesUseCase();
    final storedIds = storedRoutes.map((route) => route.id).toSet();
    final updated = state.results
        .map((item) => item.copyWith(isStored: storedIds.contains(item.id)))
        .toList(growable: false);
    emit(state.copyWith(results: updated));
  }

  @override
  Future<void> close() {
    _watchStoredRoutesUseCase.removeListener(_handleStoredRoutesChanged);
    return super.close();
  }

  Future<void> _handleStoredRoutesChanged() async {
    if (isClosed) {
      return;
    }
    add(const RouteResultsStoredRoutesChanged());
  }
}
