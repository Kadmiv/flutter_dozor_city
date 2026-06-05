import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_dozor_city/core/domain/entities/vehicle.dart';
import 'package:flutter_dozor_city/core/time/app_clock.dart';
import 'package:flutter_dozor_city/core/time/polling_scheduler.dart';
import 'package:flutter_dozor_city/features/live_tracking/domain/entities/animated_vehicle.dart';
import 'package:flutter_dozor_city/features/live_tracking/domain/services/live_vehicle_motion_resolver.dart';
import 'package:flutter_dozor_city/features/live_tracking/domain/usecases/get_city_vehicles_use_case.dart';

import 'package:flutter_dozor_city/core/error/failures.dart';

class LiveTrackingState {
  const LiveTrackingState({
    this.isLoading = false,
    this.animatedVehicles = const [],
    this.activeCityId,
    this.routeIds,
    this.lastUpdatedAt,
    this.failure,
  });

  final bool isLoading;
  final List<AnimatedVehicle> animatedVehicles;
  final String? activeCityId;
  final List<String>? routeIds;
  final DateTime? lastUpdatedAt;
  final AppFailure? failure;

  List<Vehicle> get vehicles {
    final now = DateTime.now();
    return animatedVehicles
        .map((vehicle) => vehicle.vehicleAt(now))
        .toList(growable: false);
  }

  LiveTrackingState copyWith({
    bool? isLoading,
    List<AnimatedVehicle>? animatedVehicles,
    String? activeCityId,
    List<String>? routeIds,
    DateTime? lastUpdatedAt,
    AppFailure? failure,
    bool clearFailure = false,
    bool clearRouteIds = false,
  }) {
    return LiveTrackingState(
      isLoading: isLoading ?? this.isLoading,
      animatedVehicles: animatedVehicles ?? this.animatedVehicles,
      activeCityId: activeCityId ?? this.activeCityId,
      routeIds: clearRouteIds ? null : (routeIds ?? this.routeIds),
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
    LiveVehicleMotionResolver motionResolver =
        const LiveVehicleMotionResolver(),
  }) : _getCityVehiclesUseCase = getCityVehiclesUseCase,
       _pollingScheduler = pollingScheduler,
       _clock = clock,
       _motionResolver = motionResolver,
       super(const LiveTrackingState());

  final GetCityVehiclesUseCase _getCityVehiclesUseCase;
  final PollingScheduler _pollingScheduler;
  final AppClock _clock;
  final LiveVehicleMotionResolver _motionResolver;

  Future<void> start(String cityId, {List<String>? routeIds}) async {
    await stop();
    emit(
      state.copyWith(
        activeCityId: cityId,
        routeIds: routeIds,
        isLoading: true,
        clearFailure: true,
        clearRouteIds: routeIds == null,
      ),
    );
    await _load(cityId, routeIds: routeIds);
    _pollingScheduler.start(
      const Duration(seconds: 10),
      () => _load(state.activeCityId!, routeIds: state.routeIds),
    );
  }

  Future<void> updateFilters(List<String>? routeIds) async {
    final cityId = state.activeCityId;
    if (cityId == null) return;

    emit(
      state.copyWith(
        routeIds: routeIds,
        clearRouteIds: routeIds == null,
        clearFailure: true,
      ),
    );
    await _load(cityId, routeIds: routeIds);
  }

  Future<void> stop() async {
    _pollingScheduler.stop();
  }

  Future<void> _load(String cityId, {List<String>? routeIds}) async {
    try {
      final vehicles = await _getCityVehiclesUseCase(
        cityId,
        routeIds: routeIds,
      );
      final now = _clock.now();
      final animatedVehicles = _motionResolver.resolve(
        previous: state.animatedVehicles,
        next: vehicles,
        now: now,
        previousUpdatedAt: state.lastUpdatedAt,
      );
      emit(
        state.copyWith(
          isLoading: false,
          animatedVehicles: animatedVehicles,
          activeCityId: cityId,
          lastUpdatedAt: now,
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

  @override
  Future<void> close() async {
    await stop();
    return super.close();
  }
}
