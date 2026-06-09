// ignore_for_file: invalid_use_of_visible_for_testing_member

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_dozor_city/core/domain/entities/selected_map_routes.dart';
import 'package:flutter_dozor_city/core/domain/entities/transport_route.dart';
import 'package:flutter_dozor_city/core/domain/entities/route_status_filter.dart';
import 'package:flutter_dozor_city/core/error/failures.dart';
import 'package:flutter_dozor_city/features/main_map/domain/usecases/get_routes_by_type_use_case.dart';
import 'package:flutter_dozor_city/features/main_map/domain/usecases/main_map_session_use_cases.dart';

sealed class MapRoutesEvent extends Equatable {
  const MapRoutesEvent();

  @override
  List<Object?> get props => const [];
}

final class MapRoutesRestored extends MapRoutesEvent {
  const MapRoutesRestored(this.cityId);

  final String cityId;

  @override
  List<Object?> get props => [cityId];
}

final class MapTransportTypeSelected extends MapRoutesEvent {
  const MapTransportTypeSelected(this.cityId, this.type);

  final String cityId;
  final int type;

  @override
  List<Object?> get props => [cityId, type];
}

final class MapRouteSelected extends MapRoutesEvent {
  const MapRouteSelected(this.cityId, this.route);

  final String cityId;
  final TransportRoute route;

  @override
  List<Object?> get props => [cityId, route];
}

final class MapActiveRouteSelected extends MapRoutesEvent {
  const MapActiveRouteSelected(this.cityId, this.route);

  final String cityId;
  final TransportRoute route;

  @override
  List<Object?> get props => [cityId, route];
}

final class MapRouteRemoved extends MapRoutesEvent {
  const MapRouteRemoved(this.routeId);

  final String routeId;

  @override
  List<Object?> get props => [routeId];
}

final class MapStatusFilterChanged extends MapRoutesEvent {
  const MapStatusFilterChanged(this.statusFilter);

  final RouteStatusFilter statusFilter;

  @override
  List<Object?> get props => [statusFilter];
}

final class MapRoutesResetRequested extends MapRoutesEvent {
  const MapRoutesResetRequested();
}

class MapRoutesState extends Equatable {
  const MapRoutesState({
    this.transportType = 0,
    this.availableRoutes = const [],
    this.selectedRoutes = const [],
    this.selectedStatus = RouteStatusFilter.all,
    this.activeCityId,
    this.activeRouteId,
    this.isLoading = false,
    this.failure,
  });

  final int transportType;
  final List<TransportRoute> availableRoutes;
  final List<TransportRoute> selectedRoutes;
  final RouteStatusFilter selectedStatus;
  final String? activeCityId;
  final String? activeRouteId;
  final bool isLoading;
  final AppFailure? failure;

  MapRoutesState copyWith({
    int? transportType,
    List<TransportRoute>? availableRoutes,
    List<TransportRoute>? selectedRoutes,
    RouteStatusFilter? selectedStatus,
    String? activeCityId,
    String? activeRouteId,
    bool? isLoading,
    bool clearAvailableRoutes = false,
    bool clearSelectedRoutes = false,
    bool clearActiveCityId = false,
    bool clearActiveRouteId = false,
    AppFailure? failure,
    bool clearFailure = false,
  }) {
    return MapRoutesState(
      transportType: transportType ?? this.transportType,
      availableRoutes: clearAvailableRoutes
          ? const []
          : (availableRoutes ?? this.availableRoutes),
      selectedRoutes: clearSelectedRoutes
          ? const []
          : (selectedRoutes ?? this.selectedRoutes),
      selectedStatus: selectedStatus ?? this.selectedStatus,
      activeCityId: clearActiveCityId
          ? null
          : (activeCityId ?? this.activeCityId),
      activeRouteId: clearActiveRouteId
          ? null
          : (activeRouteId ?? this.activeRouteId),
      isLoading: isLoading ?? this.isLoading,
      failure: clearFailure ? null : (failure ?? this.failure),
    );
  }

  @override
  List<Object?> get props => [
    transportType,
    availableRoutes,
    selectedRoutes,
    selectedStatus,
    activeCityId,
    activeRouteId,
    isLoading,
    failure,
  ];
}

class MapRoutesBloc extends Bloc<MapRoutesEvent, MapRoutesState> {
  MapRoutesBloc({
    required GetRoutesByTypeUseCase getRoutesByTypeUseCase,
    required GetSelectedMapRoutesUseCase getSelectedMapRoutesUseCase,
    required SaveSelectedMapRoutesUseCase saveSelectedMapRoutesUseCase,
  })  : _getRoutesByTypeUseCase = getRoutesByTypeUseCase,
        _getSelectedMapRoutesUseCase = getSelectedMapRoutesUseCase,
        _saveSelectedMapRoutesUseCase = saveSelectedMapRoutesUseCase,
        super(const MapRoutesState()) {
    on<MapRoutesRestored>(_onRestored);
    on<MapTransportTypeSelected>(_onTransportTypeSelected);
    on<MapRouteSelected>(_onRouteSelected);
    on<MapActiveRouteSelected>(_onActiveRouteSelected);
    on<MapRouteRemoved>(_onRouteRemoved);
    on<MapStatusFilterChanged>(_onStatusFilterChanged);
    on<MapRoutesResetRequested>(_onResetRequested);
  }

  final GetRoutesByTypeUseCase _getRoutesByTypeUseCase;
  final GetSelectedMapRoutesUseCase _getSelectedMapRoutesUseCase;
  final SaveSelectedMapRoutesUseCase _saveSelectedMapRoutesUseCase;

  Future<void> restoreForCity(String cityId) async {
    final selectedMapRoutes = await _getSelectedMapRoutesUseCase(cityId);
    final transportType =
        selectedMapRoutes?.transportType ?? state.transportType;
    await _loadRoutes(
      cityId: cityId,
      transportType: transportType,
      selectedRouteIds: selectedMapRoutes?.selectedRouteIds ?? const [],
      activeRouteId: selectedMapRoutes?.activeRouteId,
    );
  }

  void setStatusFilter(RouteStatusFilter statusFilter) {
    emit(state.copyWith(selectedStatus: statusFilter));
  }

  Future<void> selectTransportType({
    required String cityId,
    required int type,
  }) async {
    final keepCurrentSelection =
        state.activeCityId == cityId && state.transportType == type;
    await _loadRoutes(
      cityId: cityId,
      transportType: type,
      selectedRouteIds: keepCurrentSelection
          ? state.selectedRoutes.map((route) => route.id).toList(growable: false)
          : const [],
      activeRouteId: keepCurrentSelection ? state.activeRouteId : null,
    );
    await _persistSelection(
      selectedRoutes: keepCurrentSelection ? state.selectedRoutes : const [],
      activeRouteId: keepCurrentSelection ? state.activeRouteId : null,
    );
  }

  Future<void> selectRoute({
    required String cityId,
    required TransportRoute route,
  }) async {
    final isSelected = state.selectedRoutes.contains(route);
    final isActive = state.activeRouteId == route.id;

    if (isSelected && isActive) {
      await removeRoute(route.id);
      return;
    }

    emit(
      state.copyWith(
        activeCityId: cityId,
        activeRouteId: route.id,
        selectedRoutes: isSelected
            ? state.selectedRoutes
            : [...state.selectedRoutes, route],
      ),
    );
    await _persistSelection();
  }

  Future<void> setActiveRoute({
    required String cityId,
    required TransportRoute route,
  }) async {
    if (!state.selectedRoutes.contains(route)) {
      await selectRoute(cityId: cityId, route: route);
      return;
    }
    emit(state.copyWith(activeCityId: cityId, activeRouteId: route.id));
    await _persistSelection();
  }

  Future<void> removeRoute(String routeId) async {
    final remainingRoutes = state.selectedRoutes
        .where((route) => route.id != routeId)
        .toList(growable: false);
    final removedActiveRoute = state.activeRouteId == routeId;

    if (!removedActiveRoute) {
      emit(state.copyWith(selectedRoutes: remainingRoutes));
      await _persistSelection(selectedRoutes: remainingRoutes);
      return;
    }

    if (remainingRoutes.isEmpty) {
      emit(
        state.copyWith(
          selectedRoutes: remainingRoutes,
          clearActiveRouteId: true,
        ),
      );
      await _persistSelection(
        selectedRoutes: remainingRoutes,
        activeRouteId: null,
      );
      return;
    }

    final fallbackRoute = remainingRoutes.last;
    emit(
      state.copyWith(
        selectedRoutes: remainingRoutes,
        activeRouteId: fallbackRoute.id,
      ),
    );
    await _persistSelection(
      selectedRoutes: remainingRoutes,
      activeRouteId: fallbackRoute.id,
    );
  }

  void reset() {
    emit(const MapRoutesState());
  }

  Future<void> _onRestored(
    MapRoutesRestored event,
    Emitter<MapRoutesState> emit,
  ) async {
    final selectedMapRoutes = await _getSelectedMapRoutesUseCase(event.cityId);
    final transportType =
        selectedMapRoutes?.transportType ?? state.transportType;
    await _loadRoutes(
      cityId: event.cityId,
      transportType: transportType,
      selectedRouteIds: selectedMapRoutes?.selectedRouteIds ?? const [],
      activeRouteId: selectedMapRoutes?.activeRouteId,
    );
  }

  Future<void> _onTransportTypeSelected(
    MapTransportTypeSelected event,
    Emitter<MapRoutesState> emit,
  ) async {
    final keepCurrentSelection =
        state.activeCityId == event.cityId && state.transportType == event.type;
    await _loadRoutes(
      cityId: event.cityId,
      transportType: event.type,
      selectedRouteIds: keepCurrentSelection
          ? state.selectedRoutes.map((route) => route.id).toList(growable: false)
          : const [],
      activeRouteId: keepCurrentSelection ? state.activeRouteId : null,
    );
    await _persistSelection(
      selectedRoutes: keepCurrentSelection ? state.selectedRoutes : const [],
      activeRouteId: keepCurrentSelection ? state.activeRouteId : null,
    );
  }

  Future<void> _onRouteSelected(
    MapRouteSelected event,
    Emitter<MapRoutesState> emit,
  ) async {
    final isSelected = state.selectedRoutes.contains(event.route);
    final isActive = state.activeRouteId == event.route.id;
    if (isSelected && isActive) {
      add(MapRouteRemoved(event.route.id));
      return;
    }
    emit(
      state.copyWith(
        activeCityId: event.cityId,
        activeRouteId: event.route.id,
        selectedRoutes: isSelected
            ? state.selectedRoutes
            : [...state.selectedRoutes, event.route],
      ),
    );
    await _persistSelection();
  }

  Future<void> _onActiveRouteSelected(
    MapActiveRouteSelected event,
    Emitter<MapRoutesState> emit,
  ) async {
    if (!state.selectedRoutes.contains(event.route)) {
      add(MapRouteSelected(event.cityId, event.route));
      return;
    }
    emit(state.copyWith(activeCityId: event.cityId, activeRouteId: event.route.id));
    await _persistSelection();
  }

  Future<void> _onRouteRemoved(
    MapRouteRemoved event,
    Emitter<MapRoutesState> emit,
  ) async {
    final remainingRoutes = state.selectedRoutes
        .where((route) => route.id != event.routeId)
        .toList(growable: false);
    final removedActiveRoute = state.activeRouteId == event.routeId;
    if (!removedActiveRoute) {
      emit(state.copyWith(selectedRoutes: remainingRoutes));
      await _persistSelection(selectedRoutes: remainingRoutes);
      return;
    }
    if (remainingRoutes.isEmpty) {
      emit(
        state.copyWith(
          selectedRoutes: remainingRoutes,
          clearActiveRouteId: true,
        ),
      );
      await _persistSelection(
        selectedRoutes: remainingRoutes,
        activeRouteId: null,
      );
      return;
    }
    final fallbackRoute = remainingRoutes.last;
    emit(
      state.copyWith(
        selectedRoutes: remainingRoutes,
        activeRouteId: fallbackRoute.id,
      ),
    );
    await _persistSelection(
      selectedRoutes: remainingRoutes,
      activeRouteId: fallbackRoute.id,
    );
  }

  void _onStatusFilterChanged(
    MapStatusFilterChanged event,
    Emitter<MapRoutesState> emit,
  ) {
    emit(state.copyWith(selectedStatus: event.statusFilter));
  }

  void _onResetRequested(
    MapRoutesResetRequested event,
    Emitter<MapRoutesState> emit,
  ) {
    emit(const MapRoutesState());
  }

  Future<void> _loadRoutes({
    required String cityId,
    required int transportType,
    required List<String> selectedRouteIds,
    required String? activeRouteId,
  }) async {
    emit(
      state.copyWith(
        transportType: transportType,
        activeCityId: cityId,
        isLoading: true,
        clearAvailableRoutes: true,
        clearSelectedRoutes: true,
        clearActiveRouteId: true,
        clearFailure: true,
      ),
    );
    try {
      final routes = await _getRoutesByTypeUseCase(
        cityId: cityId,
        transportType: transportType,
      );
      final selectedRoutes = routes
          .where((route) => selectedRouteIds.contains(route.id))
          .toList(growable: false);
      final resolvedActiveRouteId = selectedRoutes.isEmpty
          ? null
          : (selectedRoutes.any((route) => route.id == activeRouteId)
                ? activeRouteId
                : selectedRoutes.last.id);
      emit(
        state.copyWith(
          transportType: transportType,
          availableRoutes: routes,
          selectedRoutes: selectedRoutes,
          activeRouteId: resolvedActiveRouteId,
          isLoading: false,
        ),
      );
    } on AppFailure catch (e) {
      emit(state.copyWith(isLoading: false, failure: e));
    } catch (e) {
      emit(
        state.copyWith(isLoading: false, failure: ParseFailure(e.toString())),
      );
    }
  }

  Future<void> _persistSelection({
    List<TransportRoute>? selectedRoutes,
    String? activeRouteId,
  }) async {
    final cityId = state.activeCityId;
    if (cityId == null) {
      return;
    }
    final routes = selectedRoutes ?? state.selectedRoutes;
    await _saveSelectedMapRoutesUseCase(
      cityId,
      SelectedMapRoutes(
        transportType: state.transportType,
        selectedRouteIds: routes.map((route) => route.id).toList(growable: false),
        activeRouteId: activeRouteId ?? state.activeRouteId,
      ),
    );
  }
}
