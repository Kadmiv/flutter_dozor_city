import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_dozor_city/core/domain/entities/city.dart';
import 'package:flutter_dozor_city/features/city_selection/domain/usecases/get_cities_use_case.dart';
import 'package:flutter_dozor_city/features/city_selection/domain/usecases/select_city_use_case.dart';

class CitySelectionState {
  const CitySelectionState({
    this.cities = const [],
    this.isLoading = false,
    this.isSubmitting = false,
    this.selectedCity,
  });

  final List<City> cities;
  final bool isLoading;
  final bool isSubmitting;
  final City? selectedCity;

  CitySelectionState copyWith({
    List<City>? cities,
    bool? isLoading,
    bool? isSubmitting,
    City? selectedCity,
  }) {
    return CitySelectionState(
      cities: cities ?? this.cities,
      isLoading: isLoading ?? this.isLoading,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      selectedCity: selectedCity ?? this.selectedCity,
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
    emit(state.copyWith(isLoading: true));
    final cities = await _getCitiesUseCase();
    emit(state.copyWith(isLoading: false, cities: cities));
  }

  Future<void> selectCity(City city) async {
    emit(state.copyWith(isSubmitting: true, selectedCity: city));
    await _selectCityUseCase(city);
    emit(state.copyWith(isSubmitting: false, selectedCity: city));
  }
}
