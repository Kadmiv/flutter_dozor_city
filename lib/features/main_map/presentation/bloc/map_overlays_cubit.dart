import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_dozor_city/core/domain/entities/arrival_info.dart';
import 'package:flutter_dozor_city/core/domain/entities/route_zone.dart';
import 'package:flutter_dozor_city/core/domain/entities/transport_route.dart';
import 'package:flutter_dozor_city/features/main_map/domain/usecases/get_arrival_by_zone_use_case.dart';
import 'package:flutter_dozor_city/features/main_map/domain/usecases/get_route_zones_use_case.dart';
import 'package:flutter_dozor_city/features/main_map/domain/usecases/get_routes_by_type_use_case.dart';

class MapOverlaysState {
  const MapOverlaysState({
    this.transportType = 0,
    this.availableRoutes = const [],
    this.selectedRoutes = const [],
    this.routeZones = const [],
    this.arrivalInfo,
    this.activeCityId,
    this.activeZoneId,
    this.activeRouteId,
    this.isLoading = false,
  });

  final int transportType;
  final List<TransportRoute> availableRoutes;
  final List<TransportRoute> selectedRoutes;
  final List<RouteZone> routeZones;
  final ArrivalInfo? arrivalInfo;
  final String? activeCityId;
  final String? activeZoneId;
  final String? activeRouteId;
  final bool isLoading;

  MapOverlaysState copyWith({
    int? transportType,
    List<TransportRoute>? availableRoutes,
    List<TransportRoute>? selectedRoutes,
    List<RouteZone>? routeZones,
    ArrivalInfo? arrivalInfo,
    String? activeCityId,
    String? activeZoneId,
    String? activeRouteId,
    bool? isLoading,
    bool clearAvailableRoutes = false,
    bool clearSelectedRoutes = false,
    bool clearRouteZones = false,
    bool clearArrivalInfo = false,
    bool clearActiveCityId = false,
    bool clearActiveZoneId = false,
    bool clearActiveRouteId = false,
  }) {
    return MapOverlaysState(
      transportType: transportType ?? this.transportType,
      availableRoutes: clearAvailableRoutes
          ? const []
          : availableRoutes ?? this.availableRoutes,
      selectedRoutes: clearSelectedRoutes
          ? const []
          : selectedRoutes ?? this.selectedRoutes,
      routeZones: clearRouteZones ? const [] : routeZones ?? this.routeZones,
      arrivalInfo: clearArrivalInfo ? null : arrivalInfo ?? this.arrivalInfo,
      activeCityId: clearActiveCityId ? null : activeCityId ?? this.activeCityId,
      activeZoneId: clearActiveZoneId ? null : activeZoneId ?? this.activeZoneId,
      activeRouteId: clearActiveRouteId
          ? null
          : activeRouteId ?? this.activeRouteId,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

class MapOverlaysCubit extends Cubit<MapOverlaysState> {
  MapOverlaysCubit({
    required GetRoutesByTypeUseCase getRoutesByTypeUseCase,
    required GetRouteZonesUseCase getRouteZonesUseCase,
    required GetArrivalByZoneUseCase getArrivalByZoneUseCase,
  })  : _getRoutesByTypeUseCase = getRoutesByTypeUseCase,
        _getRouteZonesUseCase = getRouteZonesUseCase,
        _getArrivalByZoneUseCase = getArrivalByZoneUseCase,
        super(const MapOverlaysState());

  final GetRoutesByTypeUseCase _getRoutesByTypeUseCase;
  final GetRouteZonesUseCase _getRouteZonesUseCase;
  final GetArrivalByZoneUseCase _getArrivalByZoneUseCase;
  Timer? _arrivalPollingTimer;

  Future<void> selectTransportType({
    required String cityId,
    required int type,
  }) async {
    _stopArrivalPolling();
    emit(
      state.copyWith(
        transportType: type,
        activeCityId: cityId,
        isLoading: true,
        clearSelectedRoutes: true,
        clearRouteZones: true,
        clearArrivalInfo: true,
        clearActiveZoneId: true,
        clearActiveRouteId: true,
      ),
    );
    final routes = await _getRoutesByTypeUseCase(
      cityId: cityId,
      transportType: type,
    );
    emit(
      state.copyWith(
        transportType: type,
        availableRoutes: routes,
        isLoading: false,
      ),
    );
  }

  Future<void> selectRoute({
    required String cityId,
    required TransportRoute route,
  }) async {
    _stopArrivalPolling();
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
        isLoading: true,
        clearRouteZones: true,
        clearArrivalInfo: true,
        clearActiveZoneId: true,
      ),
    );
    final zones = await _getRouteZonesUseCase(route.id);
    emit(
      state.copyWith(
        selectedRoutes: isSelected ? state.selectedRoutes : [...state.selectedRoutes, route],
        activeCityId: cityId,
        activeRouteId: route.id,
        routeZones: zones,
        isLoading: false,
      ),
    );
  }

  Future<void> setActiveRoute({
    required String cityId,
    required TransportRoute route,
  }) async {
    if (!state.selectedRoutes.contains(route)) {
      await selectRoute(cityId: cityId, route: route);
      return;
    }
    _stopArrivalPolling();
    emit(
      state.copyWith(
        activeCityId: cityId,
        activeRouteId: route.id,
        isLoading: true,
        clearRouteZones: true,
        clearArrivalInfo: true,
        clearActiveZoneId: true,
      ),
    );
    final zones = await _getRouteZonesUseCase(route.id);
    emit(
      state.copyWith(
        activeCityId: cityId,
        activeRouteId: route.id,
        routeZones: zones,
        isLoading: false,
      ),
    );
  }

  Future<void> loadArrival({
    required String cityId,
    required String zoneId,
  }) async {
    _stopArrivalPolling();
    emit(
      state.copyWith(
        isLoading: true,
        activeCityId: cityId,
        activeZoneId: zoneId,
      ),
    );
    await _loadArrival(cityId: cityId, zoneId: zoneId);
    _arrivalPollingTimer = Timer.periodic(
      const Duration(seconds: 15),
      (_) => _loadArrival(cityId: cityId, zoneId: zoneId),
    );
  }

  Future<void> removeRoute(String routeId) async {
    final remainingRoutes = state.selectedRoutes
        .where((route) => route.id != routeId)
        .toList(growable: false);
    final removedActiveRoute = state.activeRouteId == routeId;
    if (!removedActiveRoute) {
      emit(state.copyWith(selectedRoutes: remainingRoutes));
      return;
    }
    _stopArrivalPolling();
    if (remainingRoutes.isEmpty) {
      emit(
        state.copyWith(
          selectedRoutes: remainingRoutes,
          clearActiveRouteId: true,
          clearRouteZones: true,
          clearArrivalInfo: true,
          clearActiveZoneId: true,
        ),
      );
      return;
    }
    final fallbackRoute = remainingRoutes.last;
    emit(
      state.copyWith(
        selectedRoutes: remainingRoutes,
        activeRouteId: fallbackRoute.id,
        isLoading: true,
        clearRouteZones: true,
        clearArrivalInfo: true,
        clearActiveZoneId: true,
      ),
    );
    final zones = await _getRouteZonesUseCase(fallbackRoute.id);
    emit(
      state.copyWith(
        selectedRoutes: remainingRoutes,
        activeRouteId: fallbackRoute.id,
        routeZones: zones,
        isLoading: false,
      ),
    );
  }

  Future<void> _loadArrival({
    required String cityId,
    required String zoneId,
  }) async {
    final arrivalInfo = await _getArrivalByZoneUseCase(
      cityId: cityId,
      zoneId: zoneId,
    );
    emit(
      state.copyWith(
        arrivalInfo: arrivalInfo,
        activeCityId: cityId,
        activeZoneId: zoneId,
        isLoading: false,
      ),
    );
  }

  void _stopArrivalPolling() {
    _arrivalPollingTimer?.cancel();
    _arrivalPollingTimer = null;
  }

  void reset() {
    _stopArrivalPolling();
    emit(const MapOverlaysState());
  }

  @override
  Future<void> close() {
    _stopArrivalPolling();
    return super.close();
  }
}
