import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_dozor_city/features/live_tracking/domain/entities/vehicle_entity.dart';
import 'package:flutter_dozor_city/features/live_tracking/domain/usecases/get_city_vehicles_use_case.dart';

class LiveTrackingState {
  const LiveTrackingState({
    this.isLoading = false,
    this.vehicles = const [],
    this.activeCityId,
    this.routeIds,
    this.lastUpdatedAt,
  });

  final bool isLoading;
  final List<VehicleEntity> vehicles;
  final String? activeCityId;
  final List<String>? routeIds;
  final DateTime? lastUpdatedAt;

  LiveTrackingState copyWith({
    bool? isLoading,
    List<VehicleEntity>? vehicles,
    String? activeCityId,
    List<String>? routeIds,
    DateTime? lastUpdatedAt,
  }) {
    return LiveTrackingState(
      isLoading: isLoading ?? this.isLoading,
      vehicles: vehicles ?? this.vehicles,
      activeCityId: activeCityId ?? this.activeCityId,
      routeIds: routeIds ?? this.routeIds,
      lastUpdatedAt: lastUpdatedAt ?? this.lastUpdatedAt,
    );
  }
}

class LiveTrackingCubit extends Cubit<LiveTrackingState> {
  LiveTrackingCubit({
    required GetCityVehiclesUseCase getCityVehiclesUseCase,
  })  : _getCityVehiclesUseCase = getCityVehiclesUseCase,
        super(const LiveTrackingState());

  final GetCityVehiclesUseCase _getCityVehiclesUseCase;
  Timer? _pollingTimer;

  Future<void> start(String cityId, {List<String>? routeIds}) async {
    await stop();
    emit(state.copyWith(
      activeCityId: cityId,
      routeIds: routeIds,
      isLoading: true,
    ));
    await _load(cityId, routeIds: routeIds);
    _pollingTimer = Timer.periodic(
      const Duration(seconds: 10),
      (_) => _load(state.activeCityId!, routeIds: state.routeIds),
    );
  }

  Future<void> updateFilters(List<String>? routeIds) async {
    final cityId = state.activeCityId;
    if (cityId == null) return;
    
    emit(state.copyWith(routeIds: routeIds));
    await _load(cityId, routeIds: routeIds);
  }

  Future<void> stop() async {
    _pollingTimer?.cancel();
    _pollingTimer = null;
  }

  Future<void> _load(String cityId, {List<String>? routeIds}) async {
    final vehicles = await _getCityVehiclesUseCase(cityId, routeIds: routeIds);
    emit(
      state.copyWith(
        isLoading: false,
        vehicles: vehicles,
        activeCityId: cityId,
        lastUpdatedAt: DateTime.now(),
      ),
    );
  }

  @override
  Future<void> close() async {
    await stop();
    return super.close();
  }
}
