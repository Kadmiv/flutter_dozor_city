import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_dozor_city/core/domain/entities/vehicle.dart';
import 'package:flutter_dozor_city/core/time/app_clock.dart';
import 'package:flutter_dozor_city/core/time/polling_scheduler.dart';
import 'package:flutter_dozor_city/features/live_tracking/domain/usecases/get_city_vehicles_use_case.dart';

import 'package:flutter_dozor_city/core/error/failures.dart';

class LiveTrackingState {
  const LiveTrackingState({
    this.isLoading = false,
    this.vehicles = const [],
    this.activeCityId,
    this.routeIds,
    this.lastUpdatedAt,
    this.failure,
  });

  final bool isLoading;
  final List<Vehicle> vehicles;
  final String? activeCityId;
  final List<String>? routeIds;
  final DateTime? lastUpdatedAt;
  final AppFailure? failure;

  LiveTrackingState copyWith({
    bool? isLoading,
    List<Vehicle>? vehicles,
    String? activeCityId,
    List<String>? routeIds,
    DateTime? lastUpdatedAt,
    AppFailure? failure,
    bool clearFailure = false,
  }) {
    return LiveTrackingState(
      isLoading: isLoading ?? this.isLoading,
      vehicles: vehicles ?? this.vehicles,
      activeCityId: activeCityId ?? this.activeCityId,
      routeIds: routeIds ?? this.routeIds,
      lastUpdatedAt: lastUpdatedAt ?? this.lastUpdatedAt,
      failure: clearFailure ? null : (failure ?? this.failure),
    );
  }
}

class LiveTrackingCubit extends Cubit<LiveTrackingState> {
  LiveTrackingCubit({
    required GetCityVehiclesUseCase getCityVehiclesUseCase,
    required PollingScheduler pollingScheduler,
    required AppClock clock,
  })  : _getCityVehiclesUseCase = getCityVehiclesUseCase,
        _pollingScheduler = pollingScheduler,
        _clock = clock,
        super(const LiveTrackingState());

  final GetCityVehiclesUseCase _getCityVehiclesUseCase;
  final PollingScheduler _pollingScheduler;
  final AppClock _clock;

  Future<void> start(String cityId, {List<String>? routeIds}) async {
    await stop();
    emit(state.copyWith(
      activeCityId: cityId,
      routeIds: routeIds,
      isLoading: true,
      clearFailure: true,
    ));
    await _load(cityId, routeIds: routeIds);
    _pollingScheduler.start(
      const Duration(seconds: 10),
      () => _load(state.activeCityId!, routeIds: state.routeIds),
    );
  }

  Future<void> updateFilters(List<String>? routeIds) async {
    final cityId = state.activeCityId;
    if (cityId == null) return;
    
    emit(state.copyWith(routeIds: routeIds, clearFailure: true));
    await _load(cityId, routeIds: routeIds);
  }

  Future<void> stop() async {
    _pollingScheduler.stop();
  }

  Future<void> _load(String cityId, {List<String>? routeIds}) async {
    try {
      final vehicles = await _getCityVehiclesUseCase(cityId, routeIds: routeIds);
      emit(
        state.copyWith(
          isLoading: false,
          vehicles: vehicles,
          activeCityId: cityId,
          lastUpdatedAt: _clock.now(),
        ),
      );
    } on AppFailure catch (e) {
      emit(state.copyWith(isLoading: false, failure: e));
    } catch (e) {
      emit(state.copyWith(isLoading: false, failure: ParseFailure(e.toString())));
    }
  }

  @override
  Future<void> close() async {
    await stop();
    return super.close();
  }
}
