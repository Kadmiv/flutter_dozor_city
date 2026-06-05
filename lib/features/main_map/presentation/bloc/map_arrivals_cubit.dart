import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_dozor_city/core/domain/entities/arrival_info.dart';
import 'package:flutter_dozor_city/core/domain/entities/route_zone.dart';
import 'package:flutter_dozor_city/core/error/failures.dart';
import 'package:flutter_dozor_city/core/time/polling_scheduler.dart';
import 'package:flutter_dozor_city/features/main_map/domain/usecases/get_arrival_by_zone_use_case.dart';
import 'package:flutter_dozor_city/features/main_map/domain/usecases/get_route_zones_use_case.dart';

class MapArrivalsState {
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
}

class MapArrivalsCubit extends Cubit<MapArrivalsState> {
  MapArrivalsCubit({
    required GetRouteZonesUseCase getRouteZonesUseCase,
    required GetArrivalByZoneUseCase getArrivalByZoneUseCase,
    required PollingScheduler pollingScheduler,
  })  : _getRouteZonesUseCase = getRouteZonesUseCase,
        _getArrivalByZoneUseCase = getArrivalByZoneUseCase,
        _pollingScheduler = pollingScheduler,
        super(const MapArrivalsState());

  final GetRouteZonesUseCase _getRouteZonesUseCase;
  final GetArrivalByZoneUseCase _getArrivalByZoneUseCase;
  final PollingScheduler _pollingScheduler;

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
    emit(
      state.copyWith(
        isLoading: true,
        activeCityId: cityId,
        activeZoneId: zoneId,
        clearArrivalInfo: true,
        clearFailure: true,
      ),
    );
    await _loadArrival(cityId: cityId, zoneId: zoneId);
    _pollingScheduler.start(
      const Duration(seconds: 15),
      () => _loadArrival(cityId: cityId, zoneId: zoneId),
    );
  }

  Future<void> _loadArrival({
    required String cityId,
    required String zoneId,
  }) async {
    try {
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
    } on AppFailure catch (e) {
      emit(state.copyWith(isLoading: false, failure: e));
    } catch (e) {
      emit(state.copyWith(isLoading: false, failure: ParseFailure(e.toString())));
    }
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
    emit(const MapArrivalsState());
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
