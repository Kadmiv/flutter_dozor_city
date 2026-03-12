import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_dozor_city/core/domain/entities/search_params.dart';
import 'package:flutter_dozor_city/core/domain/entities/selected_point.dart';
import 'package:flutter_dozor_city/core/domain/repositories/search_draft_repository.dart';
import 'package:flutter_dozor_city/features/route_search/domain/usecases/load_search_draft_use_case.dart';
import 'package:flutter_dozor_city/features/route_search/domain/usecases/save_search_draft_use_case.dart';
import 'package:flutter_dozor_city/features/route_search/domain/usecases/swap_search_points_use_case.dart';
import 'package:flutter_dozor_city/features/route_search/domain/usecases/toggle_transport_type_use_case.dart';
import 'package:flutter_dozor_city/features/route_search/domain/usecases/validate_route_search_use_case.dart';

class RouteSearchState {
  const RouteSearchState({
    this.start,
    this.end,
    this.transportTypes = const {0},
    this.errorText,
  });

  final SelectedPoint? start;
  final SelectedPoint? end;
  final Set<int> transportTypes;
  final String? errorText;

  RouteSearchState copyWith({
    SelectedPoint? start,
    SelectedPoint? end,
    Set<int>? transportTypes,
    String? errorText,
  }) {
    return RouteSearchState(
      start: start ?? this.start,
      end: end ?? this.end,
      transportTypes: transportTypes ?? this.transportTypes,
      errorText: errorText,
    );
  }

  SearchParams? get params {
    if (start == null || end == null || transportTypes.isEmpty) {
      return null;
    }
    return SearchParams(
      start: start!,
      end: end!,
      transportTypes: transportTypes,
    );
  }
}

class RouteSearchCubit extends Cubit<RouteSearchState> {
  RouteSearchCubit({
    required LoadSearchDraftUseCase loadSearchDraftUseCase,
    required SaveSearchDraftUseCase saveSearchDraftUseCase,
    required ToggleTransportTypeUseCase toggleTransportTypeUseCase,
    required SwapSearchPointsUseCase swapSearchPointsUseCase,
    required ValidateRouteSearchUseCase validateRouteSearchUseCase,
  })  : _loadSearchDraftUseCase = loadSearchDraftUseCase,
        _saveSearchDraftUseCase = saveSearchDraftUseCase,
        _toggleTransportTypeUseCase = toggleTransportTypeUseCase,
        _swapSearchPointsUseCase = swapSearchPointsUseCase,
        _validateRouteSearchUseCase = validateRouteSearchUseCase,
        super(const RouteSearchState());

  final LoadSearchDraftUseCase _loadSearchDraftUseCase;
  final SaveSearchDraftUseCase _saveSearchDraftUseCase;
  final ToggleTransportTypeUseCase _toggleTransportTypeUseCase;
  final SwapSearchPointsUseCase _swapSearchPointsUseCase;
  final ValidateRouteSearchUseCase _validateRouteSearchUseCase;

  Future<void> loadDraft() async {
    final draft = await _loadSearchDraftUseCase();
    emit(
      state.copyWith(
        start: draft.start,
        end: draft.end,
        transportTypes: draft.transportTypes,
        errorText: null,
      ),
    );
  }

  void setStart(SelectedPoint point) {
    emit(state.copyWith(start: point, errorText: null));
    _saveDraft();
  }

  void setEnd(SelectedPoint point) {
    emit(state.copyWith(end: point, errorText: null));
    _saveDraft();
  }

  void swap() {
    final swapped = _swapSearchPointsUseCase(
      start: state.start,
      end: state.end,
    );
    emit(
      state.copyWith(
        start: swapped.start,
        end: swapped.end,
        errorText: null,
      ),
    );
    _saveDraft();
  }

  void toggleTransportType(int type) {
    final next = _toggleTransportTypeUseCase(state.transportTypes, type);
    emit(state.copyWith(transportTypes: next, errorText: null));
    _saveDraft();
  }

  SearchParams? validate() {
    final result = _validateRouteSearchUseCase(
      start: state.start,
      end: state.end,
      transportTypes: state.transportTypes,
    );
    emit(state.copyWith(errorText: result.errorText));
    return result.params;
  }

  Future<void> _saveDraft() {
    return _saveSearchDraftUseCase(
      SearchDraft(
        start: state.start,
        end: state.end,
        transportTypes: state.transportTypes,
      ),
    );
  }
}
