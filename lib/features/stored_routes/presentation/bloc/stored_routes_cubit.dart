import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_dozor_city/core/domain/entities/route_result.dart';
import 'package:flutter_dozor_city/features/stored_routes/domain/usecases/delete_stored_route_use_case.dart';
import 'package:flutter_dozor_city/features/stored_routes/domain/usecases/get_stored_routes_use_case.dart';
import 'package:flutter_dozor_city/features/stored_routes/domain/usecases/watch_stored_routes_use_case.dart';

class StoredRoutesState {
  const StoredRoutesState({
    this.isLoading = true,
    this.routes = const [],
  });

  final bool isLoading;
  final List<RouteResult> routes;

  StoredRoutesState copyWith({
    bool? isLoading,
    List<RouteResult>? routes,
  }) {
    return StoredRoutesState(
      isLoading: isLoading ?? this.isLoading,
      routes: routes ?? this.routes,
    );
  }
}

class StoredRoutesCubit extends Cubit<StoredRoutesState> {
  StoredRoutesCubit({
    required GetStoredRoutesUseCase getStoredRoutesUseCase,
    required WatchStoredRoutesUseCase watchStoredRoutesUseCase,
    required DeleteStoredRouteUseCase deleteStoredRouteUseCase,
  })  : _getStoredRoutesUseCase = getStoredRoutesUseCase,
        _watchStoredRoutesUseCase = watchStoredRoutesUseCase,
        _deleteStoredRouteUseCase = deleteStoredRouteUseCase,
        super(const StoredRoutesState()) {
    _watchStoredRoutesUseCase.addListener(_handleStoredRoutesChanged);
    _load();
  }

  final GetStoredRoutesUseCase _getStoredRoutesUseCase;
  final WatchStoredRoutesUseCase _watchStoredRoutesUseCase;
  final DeleteStoredRouteUseCase _deleteStoredRouteUseCase;

  Future<void> _load() async {
    emit(state.copyWith(isLoading: true));
    final routes = await _getStoredRoutesUseCase();
    emit(state.copyWith(isLoading: false, routes: routes));
  }

  Future<void> _handleStoredRoutesChanged() async {
    final routes = await _getStoredRoutesUseCase();
    emit(state.copyWith(routes: routes));
  }

  Future<void> deleteRoute(String routeId) async {
    await _deleteStoredRouteUseCase(routeId);
  }

  @override
  Future<void> close() {
    _watchStoredRoutesUseCase.removeListener(_handleStoredRoutesChanged);
    return super.close();
  }
}
