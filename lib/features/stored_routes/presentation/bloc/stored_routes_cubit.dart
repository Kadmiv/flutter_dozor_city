import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_dozor_city/core/domain/entities/route_result.dart';
import 'package:flutter_dozor_city/core/error/failures.dart';
import 'package:flutter_dozor_city/features/stored_routes/domain/usecases/delete_stored_route_use_case.dart';
import 'package:flutter_dozor_city/features/stored_routes/domain/usecases/get_stored_routes_use_case.dart';
import 'package:flutter_dozor_city/features/stored_routes/domain/usecases/watch_stored_routes_use_case.dart';

sealed class StoredRoutesEvent extends Equatable {
  const StoredRoutesEvent();

  @override
  List<Object?> get props => const [];
}

final class StoredRoutesStarted extends StoredRoutesEvent {
  const StoredRoutesStarted();
}

final class StoredRoutesChanged extends StoredRoutesEvent {
  const StoredRoutesChanged();
}

final class StoredRouteDeleteRequested extends StoredRoutesEvent {
  const StoredRouteDeleteRequested(this.routeId);

  final String routeId;

  @override
  List<Object?> get props => [routeId];
}

class StoredRoutesState extends Equatable {
  const StoredRoutesState({
    this.isLoading = true,
    this.routes = const [],
    this.failure,
  });

  final bool isLoading;
  final List<RouteResult> routes;
  final AppFailure? failure;

  StoredRoutesState copyWith({
    bool? isLoading,
    List<RouteResult>? routes,
    AppFailure? failure,
    bool clearFailure = false,
  }) {
    return StoredRoutesState(
      isLoading: isLoading ?? this.isLoading,
      routes: routes ?? this.routes,
      failure: clearFailure ? null : (failure ?? this.failure),
    );
  }

  @override
  List<Object?> get props => [isLoading, routes, failure];
}

class StoredRoutesBloc extends Bloc<StoredRoutesEvent, StoredRoutesState> {
  StoredRoutesBloc({
    required GetStoredRoutesUseCase getStoredRoutesUseCase,
    required WatchStoredRoutesUseCase watchStoredRoutesUseCase,
    required DeleteStoredRouteUseCase deleteStoredRouteUseCase,
  })  : _getStoredRoutesUseCase = getStoredRoutesUseCase,
        _watchStoredRoutesUseCase = watchStoredRoutesUseCase,
        _deleteStoredRouteUseCase = deleteStoredRouteUseCase,
        super(const StoredRoutesState()) {
    _watchStoredRoutesUseCase.addListener(_handleStoredRoutesChanged);
    on<StoredRoutesStarted>(_onStarted);
    on<StoredRoutesChanged>(_onChanged);
    on<StoredRouteDeleteRequested>(_onDeleteRequested);
    add(const StoredRoutesStarted());
  }

  final GetStoredRoutesUseCase _getStoredRoutesUseCase;
  final WatchStoredRoutesUseCase _watchStoredRoutesUseCase;
  final DeleteStoredRouteUseCase _deleteStoredRouteUseCase;

  Future<void> deleteRoute(String routeId) async {
    add(StoredRouteDeleteRequested(routeId));
  }

  Future<void> _onStarted(
    StoredRoutesStarted event,
    Emitter<StoredRoutesState> emit,
  ) async {
    emit(state.copyWith(isLoading: true, clearFailure: true));
    try {
      final routes = await _getStoredRoutesUseCase();
      emit(state.copyWith(isLoading: false, routes: routes));
    } on AppFailure catch (e) {
      emit(state.copyWith(isLoading: false, failure: e));
    } catch (e) {
      emit(state.copyWith(isLoading: false, failure: ParseFailure(e.toString())));
    }
  }

  Future<void> _onChanged(
    StoredRoutesChanged event,
    Emitter<StoredRoutesState> emit,
  ) async {
    try {
      final routes = await _getStoredRoutesUseCase();
      emit(state.copyWith(routes: routes));
    } on AppFailure catch (e) {
      emit(state.copyWith(failure: e));
    } catch (e) {
      emit(state.copyWith(failure: ParseFailure(e.toString())));
    }
  }

  Future<void> _onDeleteRequested(
    StoredRouteDeleteRequested event,
    Emitter<StoredRoutesState> emit,
  ) async {
    emit(state.copyWith(clearFailure: true));
    try {
      await _deleteStoredRouteUseCase(event.routeId);
    } on AppFailure catch (e) {
      emit(state.copyWith(failure: e));
    } catch (e) {
      emit(state.copyWith(failure: ParseFailure(e.toString())));
    }
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
    add(const StoredRoutesChanged());
  }
}
