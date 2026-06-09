// ignore_for_file: invalid_use_of_visible_for_testing_member

import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_dozor_city/core/domain/entities/vehicle.dart';
import 'package:flutter_dozor_city/core/time/app_clock.dart';
import 'package:flutter_dozor_city/core/time/polling_scheduler.dart';
import 'package:flutter_dozor_city/features/live_tracking/domain/entities/animated_vehicle.dart';
import 'package:flutter_dozor_city/features/live_tracking/domain/services/live_vehicle_motion_resolver.dart';
import 'package:flutter_dozor_city/features/live_tracking/domain/usecases/get_city_vehicles_use_case.dart';

import 'package:flutter_dozor_city/core/error/failures.dart';

sealed class LiveTrackingEvent extends Equatable {
  const LiveTrackingEvent();

  @override
  List<Object?> get props => const [];
}

final class LiveTrackingStarted extends LiveTrackingEvent {
  const LiveTrackingStarted(this.cityId, {this.routeIds});

  final String cityId;
  final List<String>? routeIds;

  @override
  List<Object?> get props => [cityId, routeIds];
}

final class LiveTrackingTicked extends LiveTrackingEvent {
  const LiveTrackingTicked();
}

final class LiveTrackingFiltersChanged extends LiveTrackingEvent {
  const LiveTrackingFiltersChanged(this.routeIds);

  final List<String>? routeIds;

  @override
  List<Object?> get props => [routeIds];
}

final class LiveTrackingStopped extends LiveTrackingEvent {
  const LiveTrackingStopped();
}

class LiveTrackingState extends Equatable {
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

  @override
  List<Object?> get props => [
    isLoading,
    animatedVehicles,
    activeCityId,
    routeIds,
    lastUpdatedAt,
    failure,
  ];
}

class LiveTrackingBloc extends Bloc<LiveTrackingEvent, LiveTrackingState> {
  LiveTrackingBloc({
    required GetCityVehiclesUseCase getCityVehiclesUseCase,
    required PollingScheduler pollingScheduler,
    required AppClock clock,
    LiveVehicleMotionResolver motionResolver =
        const LiveVehicleMotionResolver(),
  }) : _getCityVehiclesUseCase = getCityVehiclesUseCase,
       _pollingScheduler = pollingScheduler,
       _clock = clock,
       _motionResolver = motionResolver,
       super(const LiveTrackingState()) {
    on<LiveTrackingStarted>(_onStarted);
    on<LiveTrackingTicked>(_onTicked);
    on<LiveTrackingFiltersChanged>(_onFiltersChanged);
    on<LiveTrackingStopped>(_onStopped);
  }

  final GetCityVehiclesUseCase _getCityVehiclesUseCase;
  final PollingScheduler _pollingScheduler;
  final AppClock _clock;
  final LiveVehicleMotionResolver _motionResolver;
  String? _pollCityId;
  List<String>? _pollRouteIds;
  int _requestVersion = 0;

  Future<void> start(String cityId, {List<String>? routeIds}) async {
    await stop();
    _pollCityId = cityId;
    _pollRouteIds = routeIds;
    final requestVersion = ++_requestVersion;
    emit(
      state.copyWith(
        activeCityId: cityId,
        routeIds: routeIds,
        isLoading: true,
        clearFailure: true,
        clearRouteIds: routeIds == null,
      ),
    );
    await _load(cityId, routeIds: routeIds, requestVersion: requestVersion);
    _pollingScheduler.start(
      const Duration(seconds: 10),
      () {
        if (isClosed || _pollCityId == null) {
          return;
        }
        add(const LiveTrackingTicked());
      },
    );
  }

  Future<void> updateFilters(List<String>? routeIds) async {
    final cityId = state.activeCityId;
    if (cityId == null) return;
    _pollRouteIds = routeIds;
    emit(
      state.copyWith(
        routeIds: routeIds,
        clearRouteIds: routeIds == null,
        clearFailure: true,
      ),
    );
    await _load(
      cityId,
      routeIds: routeIds,
      requestVersion: ++_requestVersion,
    );
  }

  Future<void> stop() async {
    _pollCityId = null;
    _pollRouteIds = null;
    _requestVersion++;
    _pollingScheduler.stop();
  }

  Future<void> _onStarted(
    LiveTrackingStarted event,
    Emitter<LiveTrackingState> emit,
  ) async {
    await _stopPolling();
    _pollCityId = event.cityId;
    _pollRouteIds = event.routeIds;
    final requestVersion = ++_requestVersion;
    emit(
      state.copyWith(
        activeCityId: event.cityId,
        routeIds: event.routeIds,
        isLoading: true,
        clearFailure: true,
        clearRouteIds: event.routeIds == null,
      ),
    );
    await _load(event.cityId, routeIds: event.routeIds, requestVersion: requestVersion);
    _pollingScheduler.start(
      const Duration(seconds: 10),
      () {
        if (isClosed || _pollCityId == null) {
          return;
        }
        add(const LiveTrackingTicked());
      },
    );
  }

  Future<void> _onTicked(
    LiveTrackingTicked event,
    Emitter<LiveTrackingState> emit,
  ) async {
    final cityId = _pollCityId ?? state.activeCityId;
    if (cityId == null) {
      return;
    }
    await _load(
      cityId,
      routeIds: _pollRouteIds ?? state.routeIds,
      requestVersion: ++_requestVersion,
    );
  }

  Future<void> _onFiltersChanged(
    LiveTrackingFiltersChanged event,
    Emitter<LiveTrackingState> emit,
  ) async {
    final cityId = state.activeCityId;
    if (cityId == null) return;
    _pollRouteIds = event.routeIds;
    emit(
      state.copyWith(
        routeIds: event.routeIds,
        clearRouteIds: event.routeIds == null,
        clearFailure: true,
      ),
    );
    await _load(
      cityId,
      routeIds: event.routeIds,
      requestVersion: ++_requestVersion,
    );
  }

  Future<void> _onStopped(
    LiveTrackingStopped event,
    Emitter<LiveTrackingState> emit,
  ) async {
    _pollCityId = null;
    _pollRouteIds = null;
    _requestVersion++;
    emit(state.copyWith(isLoading: false, clearRouteIds: true));
    await _stopPolling();
  }

  Future<void> _stopPolling() async {
    _pollingScheduler.stop();
  }

  Future<void> _load(
    String cityId, {
    List<String>? routeIds,
    required int requestVersion,
  }) async {
    try {
      final vehicles = await _getCityVehiclesUseCase(
        cityId,
        routeIds: routeIds,
      );
      if (isClosed || requestVersion != _requestVersion) {
        return;
      }
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
      if (isClosed || requestVersion != _requestVersion) {
        return;
      }
      emit(state.copyWith(isLoading: false, failure: e));
    } catch (e) {
      if (isClosed || requestVersion != _requestVersion) {
        return;
      }
      emit(
        state.copyWith(isLoading: false, failure: ParseFailure(e.toString())),
      );
    }
  }

  @override
  Future<void> close() async {
    await _stopPolling();
    return super.close();
  }
}
