// ignore_for_file: invalid_use_of_visible_for_testing_member

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_dozor_city/core/domain/entities/arrival_info.dart';
import 'package:flutter_dozor_city/core/domain/entities/route_zone.dart';
import 'package:flutter_dozor_city/core/error/failures.dart';
import 'package:flutter_dozor_city/core/time/polling_scheduler.dart';
import 'package:flutter_dozor_city/features/main_map/domain/usecases/get_arrival_by_zone_use_case.dart';
import 'package:flutter_dozor_city/features/main_map/domain/usecases/get_route_zones_use_case.dart';

sealed class MapArrivalsEvent extends Equatable {
  const MapArrivalsEvent();

  @override
  List<Object?> get props => const [];
}

final class MapZonesRequested extends MapArrivalsEvent {
  const MapZonesRequested(this.cityId, this.routeId);

  final String cityId;
  final String routeId;

  @override
  List<Object?> get props => [cityId, routeId];
}

final class MapArrivalRequested extends MapArrivalsEvent {
  const MapArrivalRequested(this.cityId, this.zoneId);

  final String cityId;
  final String zoneId;

  @override
  List<Object?> get props => [cityId, zoneId];
}

final class MapArrivalTicked extends MapArrivalsEvent {
  const MapArrivalTicked(this.cityId, this.zoneId);

  final String cityId;
  final String zoneId;

  @override
  List<Object?> get props => [cityId, zoneId];
}

final class MapZonesCleared extends MapArrivalsEvent {
  const MapZonesCleared();
}

final class MapArrivalsResetRequested extends MapArrivalsEvent {
  const MapArrivalsResetRequested();
}

class MapArrivalsState extends Equatable {
  const MapArrivalsState({
    this.routeZones = const [],
    this.arrivalInfo,
    this.activeCityId,
    this.activeRouteId,
    this.activeZoneId,
    this.isLoading = false,
    this.failure,
  });

  final List<RouteZone> routeZones;
  final ArrivalInfo? arrivalInfo;
  final String? activeCityId;
  final String? activeRouteId;
  final String? activeZoneId;
  final bool isLoading;
  final AppFailure? failure;

  MapArrivalsState copyWith({
    List<RouteZone>? routeZones,
    ArrivalInfo? arrivalInfo,
    String? activeCityId,
    String? activeRouteId,
    String? activeZoneId,
    bool? isLoading,
    bool clearRouteZones = false,
    bool clearArrivalInfo = false,
    bool clearActiveCityId = false,
    bool clearActiveRouteId = false,
    bool clearActiveZoneId = false,
    AppFailure? failure,
    bool clearFailure = false,
  }) {
    return MapArrivalsState(
      routeZones: clearRouteZones ? const [] : (routeZones ?? this.routeZones),
      arrivalInfo: clearArrivalInfo ? null : (arrivalInfo ?? this.arrivalInfo),
      activeCityId: clearActiveCityId ? null : (activeCityId ?? this.activeCityId),
      activeRouteId: clearActiveRouteId ? null : (activeRouteId ?? this.activeRouteId),
      activeZoneId: clearActiveZoneId ? null : (activeZoneId ?? this.activeZoneId),
      isLoading: isLoading ?? this.isLoading,
      failure: clearFailure ? null : (failure ?? this.failure),
    );
  }

  @override
  List<Object?> get props => [
    routeZones,
    arrivalInfo,
    activeCityId,
    activeRouteId,
    activeZoneId,
    isLoading,
    failure,
  ];
}

class MapArrivalsBloc extends Bloc<MapArrivalsEvent, MapArrivalsState> {
  MapArrivalsBloc({
    required GetRouteZonesUseCase getRouteZonesUseCase,
    required GetArrivalByZoneUseCase getArrivalByZoneUseCase,
    required PollingScheduler pollingScheduler,
  })  : _getRouteZonesUseCase = getRouteZonesUseCase,
        _getArrivalByZoneUseCase = getArrivalByZoneUseCase,
        _pollingScheduler = pollingScheduler,
        super(const MapArrivalsState()) {
    on<MapZonesRequested>(_onZonesRequested);
    on<MapArrivalRequested>(_onArrivalRequested);
    on<MapArrivalTicked>(_onArrivalTicked);
    on<MapZonesCleared>(_onZonesCleared);
    on<MapArrivalsResetRequested>(_onResetRequested);
  }

  final GetRouteZonesUseCase _getRouteZonesUseCase;
  final GetArrivalByZoneUseCase _getArrivalByZoneUseCase;
  final PollingScheduler _pollingScheduler;
  int _requestVersion = 0;

  Future<void> loadZones({
    required String cityId,
    required String routeId,
  }) async {
    _stopArrivalPolling();
    emit(
      state.copyWith(
        activeCityId: cityId,
        activeRouteId: routeId,
        isLoading: true,
        clearRouteZones: true,
        clearArrivalInfo: true,
        clearActiveZoneId: true,
        clearFailure: true,
      ),
    );
    try {
      final zones = await _getRouteZonesUseCase(routeId);
      emit(
        state.copyWith(
          routeZones: zones,
          isLoading: false,
        ),
      );
    } on AppFailure catch (e) {
      emit(state.copyWith(isLoading: false, failure: e));
    } catch (e) {
      emit(state.copyWith(isLoading: false, failure: ParseFailure(e.toString())));
    }
  }

  Future<void> loadArrival({
    required String cityId,
    required String zoneId,
  }) async {
    _stopArrivalPolling();
    final requestVersion = ++_requestVersion;
    emit(
      state.copyWith(
        isLoading: true,
        activeCityId: cityId,
        activeZoneId: zoneId,
        clearArrivalInfo: true,
        clearFailure: true,
      ),
    );
    await _loadArrival(
      cityId,
      zoneId,
      requestVersion: requestVersion,
    );
    _pollingScheduler.start(
      const Duration(seconds: 15),
      () {
        if (isClosed) {
          return;
        }
        add(MapArrivalTicked(cityId, zoneId));
      },
    );
  }

  void clearZones() {
    _stopArrivalPolling();
    emit(
      state.copyWith(
        clearRouteZones: true,
        clearArrivalInfo: true,
        clearActiveRouteId: true,
        clearActiveZoneId: true,
        clearFailure: true,
      ),
    );
  }

  void reset() {
    _stopArrivalPolling();
    _requestVersion++;
    emit(const MapArrivalsState());
  }

  Future<void> _onZonesRequested(
    MapZonesRequested event,
    Emitter<MapArrivalsState> emit,
  ) async {
    _stopArrivalPolling();
    emit(
      state.copyWith(
        activeCityId: event.cityId,
        activeRouteId: event.routeId,
        isLoading: true,
        clearRouteZones: true,
        clearArrivalInfo: true,
        clearActiveZoneId: true,
        clearFailure: true,
      ),
    );
    try {
      final zones = await _getRouteZonesUseCase(event.routeId);
      emit(
        state.copyWith(
          routeZones: zones,
          isLoading: false,
        ),
      );
    } on AppFailure catch (e) {
      emit(state.copyWith(isLoading: false, failure: e));
    } catch (e) {
      emit(state.copyWith(isLoading: false, failure: ParseFailure(e.toString())));
    }
  }

  Future<void> _onArrivalRequested(
    MapArrivalRequested event,
    Emitter<MapArrivalsState> emit,
  ) async {
    _stopArrivalPolling();
    final requestVersion = ++_requestVersion;
    emit(
      state.copyWith(
        isLoading: true,
        activeCityId: event.cityId,
        activeZoneId: event.zoneId,
        clearArrivalInfo: true,
        clearFailure: true,
      ),
    );
    await _loadArrival(
      event.cityId,
      event.zoneId,
      requestVersion: requestVersion,
    );
    _pollingScheduler.start(
      const Duration(seconds: 15),
      () {
        if (isClosed) {
          return;
        }
        add(MapArrivalTicked(event.cityId, event.zoneId));
      },
    );
  }

  Future<void> _onArrivalTicked(
    MapArrivalTicked event,
    Emitter<MapArrivalsState> emit,
  ) async {
    await _loadArrival(
      event.cityId,
      event.zoneId,
      requestVersion: ++_requestVersion,
    );
  }

  void _onZonesCleared(
    MapZonesCleared event,
    Emitter<MapArrivalsState> emit,
  ) {
    _stopArrivalPolling();
    emit(
      state.copyWith(
        clearRouteZones: true,
        clearArrivalInfo: true,
        clearActiveRouteId: true,
        clearActiveZoneId: true,
        clearFailure: true,
      ),
    );
  }

  void _onResetRequested(
    MapArrivalsResetRequested event,
    Emitter<MapArrivalsState> emit,
  ) {
    _stopArrivalPolling();
    _requestVersion++;
    emit(const MapArrivalsState());
  }

  Future<void> _loadArrival(
    String cityId,
    String zoneId, {
    required int requestVersion,
  }) async {
    try {
      final arrivalInfo = await _getArrivalByZoneUseCase(
        cityId: cityId,
        zoneId: zoneId,
      );
      if (isClosed || requestVersion != _requestVersion) {
        return;
      }
      emit(
        state.copyWith(
          arrivalInfo: arrivalInfo,
          activeCityId: cityId,
          activeZoneId: zoneId,
          isLoading: false,
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
      emit(state.copyWith(isLoading: false, failure: ParseFailure(e.toString())));
    }
  }

  void _stopArrivalPolling() {
    _pollingScheduler.stop();
  }

  @override
  Future<void> close() {
    _stopArrivalPolling();
    return super.close();
  }
}
