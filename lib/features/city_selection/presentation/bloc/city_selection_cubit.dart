// ignore_for_file: invalid_use_of_visible_for_testing_member

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_dozor_city/core/domain/entities/city.dart';
import 'package:flutter_dozor_city/features/city_selection/domain/usecases/get_cities_use_case.dart';
import 'package:flutter_dozor_city/features/city_selection/domain/usecases/select_city_use_case.dart';

import 'package:flutter_dozor_city/core/error/failures.dart';

sealed class CitySelectionEvent extends Equatable {
  const CitySelectionEvent();

  @override
  List<Object?> get props => const [];
}

final class CitySelectionStarted extends CitySelectionEvent {
  const CitySelectionStarted();
}

final class CitySelectionSubmitted extends CitySelectionEvent {
  const CitySelectionSubmitted(this.city);

  final City city;

  @override
  List<Object?> get props => [city];
}

class CitySelectionState extends Equatable {
  const CitySelectionState({
    this.cities = const [],
    this.isLoading = false,
    this.isSubmitting = false,
    this.selectedCity,
    this.failure,
    this.submissionSucceeded = false,
  });

  final List<City> cities;
  final bool isLoading;
  final bool isSubmitting;
  final City? selectedCity;
  final AppFailure? failure;
  final bool submissionSucceeded;

  CitySelectionState copyWith({
    List<City>? cities,
    bool? isLoading,
    bool? isSubmitting,
    City? selectedCity,
    AppFailure? failure,
    bool? submissionSucceeded,
    bool clearFailure = false,
    bool clearSelectedCity = false,
  }) {
    return CitySelectionState(
      cities: cities ?? this.cities,
      isLoading: isLoading ?? this.isLoading,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      selectedCity: clearSelectedCity
          ? null
          : (selectedCity ?? this.selectedCity),
      failure: clearFailure ? null : (failure ?? this.failure),
      submissionSucceeded:
          submissionSucceeded ?? this.submissionSucceeded,
    );
  }

  @override
  List<Object?> get props => [
    cities,
    isLoading,
    isSubmitting,
    selectedCity,
    failure,
    submissionSucceeded,
  ];
}

class CitySelectionBloc extends Bloc<CitySelectionEvent, CitySelectionState> {
  CitySelectionBloc({
    required GetCitiesUseCase getCitiesUseCase,
    required SelectCityUseCase selectCityUseCase,
  }) : _getCitiesUseCase = getCitiesUseCase,
       _selectCityUseCase = selectCityUseCase,
       super(const CitySelectionState()) {
    on<CitySelectionStarted>(_onStarted);
    on<CitySelectionSubmitted>(_onSubmitted);
  }

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
      emit(
        state.copyWith(isLoading: false, failure: ParseFailure(e.toString())),
      );
    }
  }

  Future<void> selectCity(City city) async {
    emit(
      state.copyWith(
        isSubmitting: true,
        selectedCity: city,
        clearFailure: true,
        submissionSucceeded: false,
      ),
    );
    try {
      await _selectCityUseCase(city);
      emit(
        state.copyWith(
          isSubmitting: false,
          selectedCity: city,
          submissionSucceeded: true,
        ),
      );
    } on AppFailure catch (e) {
      emit(state.copyWith(isSubmitting: false, failure: e));
    } catch (e) {
      emit(
        state.copyWith(isSubmitting: false, failure: ParseFailure(e.toString())),
      );
    }
  }

  Future<void> _onStarted(
    CitySelectionStarted event,
    Emitter<CitySelectionState> emit,
  ) async {
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

  Future<void> _onSubmitted(
    CitySelectionSubmitted event,
    Emitter<CitySelectionState> emit,
  ) async {
    emit(
      state.copyWith(
        isSubmitting: true,
        selectedCity: event.city,
        clearFailure: true,
        submissionSucceeded: false,
      ),
    );
    try {
      await _selectCityUseCase(event.city);
      emit(
        state.copyWith(
          isSubmitting: false,
          selectedCity: event.city,
          submissionSucceeded: true,
        ),
      );
    } on AppFailure catch (e) {
      emit(state.copyWith(isSubmitting: false, failure: e));
    } catch (e) {
      emit(state.copyWith(isSubmitting: false, failure: ParseFailure(e.toString())));
    }
  }
}
