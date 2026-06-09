// ignore_for_file: invalid_use_of_visible_for_testing_member

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_dozor_city/core/domain/entities/route_zone.dart';
import 'package:flutter_dozor_city/core/error/failures.dart';
import 'package:flutter_dozor_city/features/main_map/domain/usecases/get_city_stops_use_case.dart';

sealed class MapStopsEvent extends Equatable {
  const MapStopsEvent();

  @override
  List<Object?> get props => const [];
}

final class MapStopsRequested extends MapStopsEvent {
  const MapStopsRequested(this.cityId);

  final String cityId;

  @override
  List<Object?> get props => [cityId];
}

final class MapStopsResetRequested extends MapStopsEvent {
  const MapStopsResetRequested();
}

class MapStopsState extends Equatable {
  const MapStopsState({
    this.cityStops = const [],
    this.activeCityId,
    this.isLoading = false,
    this.failure,
  });

  final List<RouteZone> cityStops;
  final String? activeCityId;
  final bool isLoading;
  final AppFailure? failure;

  MapStopsState copyWith({
    List<RouteZone>? cityStops,
    String? activeCityId,
    bool? isLoading,
    AppFailure? failure,
    bool clearCityStops = false,
    bool clearActiveCityId = false,
    bool clearFailure = false,
  }) {
    return MapStopsState(
      cityStops: clearCityStops ? const [] : (cityStops ?? this.cityStops),
      activeCityId: clearActiveCityId
          ? null
          : (activeCityId ?? this.activeCityId),
      isLoading: isLoading ?? this.isLoading,
      failure: clearFailure ? null : (failure ?? this.failure),
    );
  }

  @override
  List<Object?> get props => [cityStops, activeCityId, isLoading, failure];
}

class MapStopsBloc extends Bloc<MapStopsEvent, MapStopsState> {
  MapStopsBloc({required GetCityStopsUseCase getCityStopsUseCase})
      : _getCityStopsUseCase = getCityStopsUseCase,
        super(const MapStopsState()) {
    on<MapStopsRequested>(_onRequested);
    on<MapStopsResetRequested>(_onResetRequested);
  }

  final GetCityStopsUseCase _getCityStopsUseCase;

  Future<void> loadForCity(String cityId) async {
    emit(
      state.copyWith(
        activeCityId: cityId,
        isLoading: true,
        clearCityStops: true,
        clearFailure: true,
      ),
    );
    try {
      final stops = await _getCityStopsUseCase(cityId);
      emit(
        state.copyWith(
          activeCityId: cityId,
          cityStops: stops,
          isLoading: false,
        ),
      );
    } on AppFailure catch (e) {
      emit(state.copyWith(isLoading: false, failure: e));
    } catch (e) {
      emit(state.copyWith(isLoading: false, failure: ParseFailure(e.toString())));
    }
  }

  void reset() {
    emit(const MapStopsState());
  }

  Future<void> _onRequested(
    MapStopsRequested event,
    Emitter<MapStopsState> emit,
  ) async {
    emit(
      state.copyWith(
        activeCityId: event.cityId,
        isLoading: true,
        clearCityStops: true,
        clearFailure: true,
      ),
    );
    try {
      final stops = await _getCityStopsUseCase(event.cityId);
      emit(
        state.copyWith(
          activeCityId: event.cityId,
          cityStops: stops,
          isLoading: false,
        ),
      );
    } on AppFailure catch (e) {
      emit(state.copyWith(isLoading: false, failure: e));
    } catch (e) {
      emit(state.copyWith(isLoading: false, failure: ParseFailure(e.toString())));
    }
  }

  void _onResetRequested(
    MapStopsResetRequested event,
    Emitter<MapStopsState> emit,
  ) {
    emit(const MapStopsState());
  }
}
