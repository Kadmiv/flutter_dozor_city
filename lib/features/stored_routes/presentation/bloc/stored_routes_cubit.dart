import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_dozor_city/core/domain/entities/route_result.dart';
import 'package:flutter_dozor_city/core/domain/repositories/stored_routes_repository.dart';
import 'package:flutter_dozor_city/features/stored_routes/domain/usecases/delete_stored_route_use_case.dart';
import 'package:flutter_dozor_city/features/stored_routes/domain/usecases/get_stored_routes_use_case.dart';

class StoredRoutesState {
  const StoredRoutesState({
    this.isLoading = false,
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
    required StoredRoutesRepository storedRoutesRepository,
    required DeleteStoredRouteUseCase deleteStoredRouteUseCase,
  })  : _getStoredRoutesUseCase = getStoredRoutesUseCase,
        _storedRoutesRepository = storedRoutesRepository,
        _deleteStoredRouteUseCase = deleteStoredRouteUseCase,
        super(const StoredRoutesState()) {
    _storedRoutesRepository.addListener(_handleStoredRoutesChanged);
  }

  final GetStoredRoutesUseCase _getStoredRoutesUseCase;
  final StoredRoutesRepository _storedRoutesRepository;
  final DeleteStoredRouteUseCase _deleteStoredRouteUseCase;

  Future<void> load() async {
    emit(state.copyWith(isLoading: true));
    final routes = await _getStoredRoutesUseCase();
    emit(state.copyWith(isLoading: false, routes: routes));
  }

  Future<void> deleteRoute(String routeId) async {
    await _deleteStoredRouteUseCase(routeId);
    await load();
  }

  Future<void> _handleStoredRoutesChanged() async {
    await load();
  }

  @override
  Future<void> close() {
    _storedRoutesRepository.removeListener(_handleStoredRoutesChanged);
    return super.close();
  }
}
