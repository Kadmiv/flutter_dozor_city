import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_dozor_city/core/domain/entities/route_result.dart';
import 'package:flutter_dozor_city/core/domain/entities/search_params.dart';
import 'package:flutter_dozor_city/core/domain/repositories/stored_routes_repository.dart';
import 'package:flutter_dozor_city/features/route_results/domain/usecases/search_routes_use_case.dart';
import 'package:flutter_dozor_city/features/route_results/domain/usecases/toggle_stored_route_use_case.dart';
import 'package:flutter_dozor_city/features/stored_routes/domain/usecases/get_stored_routes_use_case.dart';

class RouteResultsState {
  const RouteResultsState({
    this.isLoading = false,
    this.results = const [],
    this.params,
  });

  final bool isLoading;
  final List<RouteResult> results;
  final SearchParams? params;

  RouteResultsState copyWith({
    bool? isLoading,
    List<RouteResult>? results,
    SearchParams? params,
  }) {
    return RouteResultsState(
      isLoading: isLoading ?? this.isLoading,
      results: results ?? this.results,
      params: params ?? this.params,
    );
  }
}

class RouteResultsCubit extends Cubit<RouteResultsState> {
  RouteResultsCubit({
    required SearchRoutesUseCase searchRoutesUseCase,
    required GetStoredRoutesUseCase getStoredRoutesUseCase,
    required StoredRoutesRepository storedRoutesRepository,
    required ToggleStoredRouteUseCase toggleStoredRouteUseCase,
  })  : _searchRoutesUseCase = searchRoutesUseCase,
        _getStoredRoutesUseCase = getStoredRoutesUseCase,
        _storedRoutesRepository = storedRoutesRepository,
        _toggleStoredRouteUseCase = toggleStoredRouteUseCase,
        super(const RouteResultsState()) {
    _storedRoutesRepository.addListener(_handleStoredRoutesChanged);
  }

  final SearchRoutesUseCase _searchRoutesUseCase;
  final GetStoredRoutesUseCase _getStoredRoutesUseCase;
  final StoredRoutesRepository _storedRoutesRepository;
  final ToggleStoredRouteUseCase _toggleStoredRouteUseCase;

  Future<void> load(Object? extra) async {
    final params = extra is SearchParams ? extra : state.params;
    if (params == null) {
      emit(state.copyWith(results: const []));
      return;
    }

    emit(state.copyWith(isLoading: true, params: params));
    final results = await _searchRoutesUseCase(params);
    final storedRoutes = await _getStoredRoutesUseCase();
    final storedIds = storedRoutes.map((route) => route.id).toSet();
    final normalized = <RouteResult>[];
    for (final result in results) {
      normalized.add(result.copyWith(isStored: storedIds.contains(result.id)));
    }
    emit(state.copyWith(isLoading: false, results: normalized, params: params));
  }

  Future<void> toggleStored(RouteResult result) async {
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

  Future<void> _handleStoredRoutesChanged() async {
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
    _storedRoutesRepository.removeListener(_handleStoredRoutesChanged);
    return super.close();
  }
}
