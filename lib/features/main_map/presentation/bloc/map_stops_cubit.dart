import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_dozor_city/core/domain/entities/route_zone.dart';
import 'package:flutter_dozor_city/core/error/failures.dart';
import 'package:flutter_dozor_city/features/main_map/domain/usecases/get_city_stops_use_case.dart';

class MapStopsState {
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
}

class MapStopsCubit extends Cubit<MapStopsState> {
  MapStopsCubit({required GetCityStopsUseCase getCityStopsUseCase})
      : _getCityStopsUseCase = getCityStopsUseCase,
        super(const MapStopsState());

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
}
