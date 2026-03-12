import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_dozor_city/core/domain/entities/selected_point.dart';
import 'package:flutter_dozor_city/features/point_select/domain/usecases/get_current_location_use_case.dart';
import 'package:flutter_dozor_city/features/point_select/domain/usecases/search_address_suggestions_use_case.dart';

class PointSelectState {
  const PointSelectState({
    this.query = '',
    this.isLoading = false,
    this.suggestions = const [],
  });

  final String query;
  final bool isLoading;
  final List<SelectedPoint> suggestions;

  PointSelectState copyWith({
    String? query,
    bool? isLoading,
    List<SelectedPoint>? suggestions,
  }) {
    return PointSelectState(
      query: query ?? this.query,
      isLoading: isLoading ?? this.isLoading,
      suggestions: suggestions ?? this.suggestions,
    );
  }
}

class PointSelectCubit extends Cubit<PointSelectState> {
  PointSelectCubit({
    required SearchAddressSuggestionsUseCase searchAddressSuggestionsUseCase,
    required GetCurrentLocationUseCase getCurrentLocationUseCase,
  })  : _searchAddressSuggestionsUseCase = searchAddressSuggestionsUseCase,
        _getCurrentLocationUseCase = getCurrentLocationUseCase,
        super(const PointSelectState());

  final SearchAddressSuggestionsUseCase _searchAddressSuggestionsUseCase;
  final GetCurrentLocationUseCase _getCurrentLocationUseCase;

  Future<void> search(String query) async {
    emit(state.copyWith(query: query, isLoading: true));
    final results = await _searchAddressSuggestionsUseCase(query);
    emit(state.copyWith(isLoading: false, suggestions: results));
  }

  Future<SelectedPoint> useCurrentLocation() {
    return _getCurrentLocationUseCase();
  }
}
