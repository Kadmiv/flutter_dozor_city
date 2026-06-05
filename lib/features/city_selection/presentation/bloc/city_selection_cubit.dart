import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_dozor_city/core/domain/entities/city.dart';
import 'package:flutter_dozor_city/features/city_selection/domain/usecases/get_cities_use_case.dart';
import 'package:flutter_dozor_city/features/city_selection/domain/usecases/select_city_use_case.dart';

import 'package:flutter_dozor_city/core/error/failures.dart';

class CitySelectionState {
  const CitySelectionState({
    this.cities = const [],
    this.isLoading = false,
    this.isSubmitting = false,
    this.selectedCity,
    this.failure,
  });

  final List<City> cities;
  final bool isLoading;
  final bool isSubmitting;
  final City? selectedCity;
  final AppFailure? failure;

  CitySelectionState copyWith({
    List<City>? cities,
    bool? isLoading,
    bool? isSubmitting,
    City? selectedCity,
    AppFailure? failure,
    bool clearFailure = false,
  }) {
    return CitySelectionState(
      cities: cities ?? this.cities,
      isLoading: isLoading ?? this.isLoading,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      selectedCity: selectedCity ?? this.selectedCity,
      failure: clearFailure ? null : (failure ?? this.failure),
    );
  }
}

class CitySelectionCubit extends Cubit<CitySelectionState> {
  CitySelectionCubit({
    required GetCitiesUseCase getCitiesUseCase,
    required SelectCityUseCase selectCityUseCase,
  }) : _getCitiesUseCase = getCitiesUseCase,
       _selectCityUseCase = selectCityUseCase,
       super(const CitySelectionState());

  final GetCitiesUseCase _getCitiesUseCase;
  final SelectCityUseCase _selectCityUseCase;

  Future<void> loadCities() async {
    emit(state.copyWith(isLoading: true, clearFailure: true));
    try {
      final cities = await _getCitiesUseCase();
      emit(state.copyWith(isLoading: false, cities: cities));
    } on AppFailure catch (e) {
      emit(state.copyWith(isLoading: false, failure: e));
    } catch (e) {
      emit(state.copyWith(isLoading: false, failure: ParseFailure(e.toString())));
    }
  }

  Future<void> selectCity(City city) async {
    emit(state.copyWith(isSubmitting: true, selectedCity: city, clearFailure: true));
    try {
      await _selectCityUseCase(city);
      emit(state.copyWith(isSubmitting: false, selectedCity: city));
    } on AppFailure catch (e) {
      emit(state.copyWith(isSubmitting: false, failure: e));
    } catch (e) {
      emit(state.copyWith(isSubmitting: false, failure: ParseFailure(e.toString())));
    }
  }
}
