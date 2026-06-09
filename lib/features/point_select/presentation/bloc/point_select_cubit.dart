import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_dozor_city/core/domain/entities/selected_point.dart';
import 'package:flutter_dozor_city/core/error/failures.dart';
import 'package:flutter_dozor_city/features/point_select/domain/usecases/get_current_location_use_case.dart';
import 'package:flutter_dozor_city/features/point_select/domain/usecases/search_address_suggestions_use_case.dart';

sealed class PointSelectEvent extends Equatable {
  const PointSelectEvent();

  @override
  List<Object?> get props => const [];
}

final class PointSelectQueryChanged extends PointSelectEvent {
  const PointSelectQueryChanged(this.query);

  final String query;

  @override
  List<Object?> get props => [query];
}

final class PointSelectCurrentLocationRequested extends PointSelectEvent {
  const PointSelectCurrentLocationRequested();
}

final class PointSelectSuggestionSelected extends PointSelectEvent {
  const PointSelectSuggestionSelected(this.point);

  final SelectedPoint point;

  @override
  List<Object?> get props => [point];
}

class PointSelectState extends Equatable {
  const PointSelectState({
    this.query = '',
    this.isLoading = false,
    this.suggestions = const [],
    this.failure,
    this.selectedPoint,
  });

  final String query;
  final bool isLoading;
  final List<SelectedPoint> suggestions;
  final AppFailure? failure;
  final SelectedPoint? selectedPoint;

  PointSelectState copyWith({
    String? query,
    bool? isLoading,
    List<SelectedPoint>? suggestions,
    AppFailure? failure,
    SelectedPoint? selectedPoint,
    bool clearFailure = false,
    bool clearSelectedPoint = false,
  }) {
    return PointSelectState(
      query: query ?? this.query,
      isLoading: isLoading ?? this.isLoading,
      suggestions: suggestions ?? this.suggestions,
      failure: clearFailure ? null : (failure ?? this.failure),
      selectedPoint: clearSelectedPoint
          ? null
          : (selectedPoint ?? this.selectedPoint),
    );
  }

  @override
  List<Object?> get props => [
    query,
    isLoading,
    suggestions,
    failure,
    selectedPoint,
  ];
}

class PointSelectBloc extends Bloc<PointSelectEvent, PointSelectState> {
  PointSelectBloc({
    required SearchAddressSuggestionsUseCase searchAddressSuggestionsUseCase,
    required GetCurrentLocationUseCase getCurrentLocationUseCase,
  })  : _searchAddressSuggestionsUseCase = searchAddressSuggestionsUseCase,
        _getCurrentLocationUseCase = getCurrentLocationUseCase,
        super(const PointSelectState()) {
    on<PointSelectQueryChanged>(_onQueryChanged);
    on<PointSelectCurrentLocationRequested>(_onCurrentLocationRequested);
    on<PointSelectSuggestionSelected>(_onSuggestionSelected);
  }

  final SearchAddressSuggestionsUseCase _searchAddressSuggestionsUseCase;
  final GetCurrentLocationUseCase _getCurrentLocationUseCase;
  Timer? _debounce;
  int _requestVersion = 0;

  Future<void> _onQueryChanged(
    PointSelectQueryChanged event,
    Emitter<PointSelectState> emit,
  ) async {
    _debounce?.cancel();
    emit(
      state.copyWith(
        query: event.query,
        isLoading: event.query.isNotEmpty,
        clearFailure: true,
        clearSelectedPoint: true,
      ),
    );
    if (event.query.isEmpty) {
      emit(state.copyWith(suggestions: const [], isLoading: false));
      return;
    }
    final version = ++_requestVersion;
    _debounce = Timer(const Duration(milliseconds: 300), () async {
      try {
        final results = await _searchAddressSuggestionsUseCase(event.query);
        if (isClosed || version != _requestVersion) {
          return;
        }
        emit(
          state.copyWith(
            isLoading: false,
            suggestions: results,
            clearSelectedPoint: true,
          ),
        );
      } on AppFailure catch (e) {
        if (isClosed || version != _requestVersion) {
          return;
        }
        emit(state.copyWith(isLoading: false, failure: e));
      } catch (e) {
        if (isClosed || version != _requestVersion) {
          return;
        }
        emit(
          state.copyWith(
            isLoading: false,
            failure: ParseFailure(e.toString()),
          ),
        );
      }
    });
  }

  Future<void> _onCurrentLocationRequested(
    PointSelectCurrentLocationRequested event,
    Emitter<PointSelectState> emit,
  ) async {
    emit(
      state.copyWith(
        isLoading: true,
        clearFailure: true,
        clearSelectedPoint: true,
      ),
    );
    try {
      final point = await _getCurrentLocationUseCase();
      if (isClosed) {
        return;
      }
      emit(
        state.copyWith(
          isLoading: false,
          selectedPoint: point,
          suggestions: [point],
        ),
      );
    } on AppFailure catch (e) {
      emit(state.copyWith(isLoading: false, failure: e));
    } catch (e) {
      emit(
        state.copyWith(
          isLoading: false,
          failure: ParseFailure(e.toString()),
        ),
      );
    }
  }

  void _onSuggestionSelected(
    PointSelectSuggestionSelected event,
    Emitter<PointSelectState> emit,
  ) {
    emit(
      state.copyWith(
        query: event.point.label,
        suggestions: [event.point],
        clearFailure: true,
        selectedPoint: event.point,
      ),
    );
  }

  @override
  Future<void> close() {
    _debounce?.cancel();
    return super.close();
  }
}
