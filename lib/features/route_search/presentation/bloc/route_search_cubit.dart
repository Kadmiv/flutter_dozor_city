import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_dozor_city/core/domain/entities/search_params.dart';
import 'package:flutter_dozor_city/core/domain/entities/selected_point.dart';
import 'package:flutter_dozor_city/core/domain/repositories/search_draft_repository.dart';
import 'package:flutter_dozor_city/features/route_search/domain/usecases/load_search_draft_use_case.dart';
import 'package:flutter_dozor_city/features/route_search/domain/usecases/save_search_draft_use_case.dart';
import 'package:flutter_dozor_city/features/route_search/domain/usecases/swap_search_points_use_case.dart';
import 'package:flutter_dozor_city/features/route_search/domain/usecases/toggle_transport_type_use_case.dart';
import 'package:flutter_dozor_city/features/route_search/domain/usecases/validate_route_search_use_case.dart';

sealed class RouteSearchEvent extends Equatable {
  const RouteSearchEvent();

  @override
  List<Object?> get props => const [];
}

final class RouteSearchDraftRequested extends RouteSearchEvent {
  const RouteSearchDraftRequested();
}

final class RouteSearchStartChanged extends RouteSearchEvent {
  const RouteSearchStartChanged(this.point);

  final SelectedPoint point;

  @override
  List<Object?> get props => [point];
}

final class RouteSearchEndChanged extends RouteSearchEvent {
  const RouteSearchEndChanged(this.point);

  final SelectedPoint point;

  @override
  List<Object?> get props => [point];
}

final class RouteSearchSwapped extends RouteSearchEvent {
  const RouteSearchSwapped();
}

final class RouteSearchTransportTypeToggled extends RouteSearchEvent {
  const RouteSearchTransportTypeToggled(this.type);

  final int type;

  @override
  List<Object?> get props => [type];
}

final class RouteSearchSubmitted extends RouteSearchEvent {
  const RouteSearchSubmitted();
}

class RouteSearchState extends Equatable {
  const RouteSearchState({
    this.start,
    this.end,
    this.transportTypes = const {0},
    this.errorText,
    this.validParams,
  });

  final SelectedPoint? start;
  final SelectedPoint? end;
  final Set<int> transportTypes;
  final String? errorText;
  final SearchParams? validParams;

  RouteSearchState copyWith({
    SelectedPoint? start,
    SelectedPoint? end,
    Set<int>? transportTypes,
    String? errorText,
    SearchParams? validParams,
    bool clearErrorText = false,
    bool clearValidParams = false,
  }) {
    return RouteSearchState(
      start: start ?? this.start,
      end: end ?? this.end,
      transportTypes: transportTypes ?? this.transportTypes,
      errorText: clearErrorText ? null : (errorText ?? this.errorText),
      validParams: clearValidParams
          ? null
          : (validParams ?? this.validParams),
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

  @override
  List<Object?> get props => [start, end, transportTypes, errorText, validParams];
}

class RouteSearchBloc extends Bloc<RouteSearchEvent, RouteSearchState> {
  RouteSearchBloc({
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
        super(const RouteSearchState()) {
    on<RouteSearchDraftRequested>(_onDraftRequested);
    on<RouteSearchStartChanged>(_onStartChanged);
    on<RouteSearchEndChanged>(_onEndChanged);
    on<RouteSearchSwapped>(_onSwapped);
    on<RouteSearchTransportTypeToggled>(_onTransportTypeToggled);
    on<RouteSearchSubmitted>(_onSubmitted);
  }

  final LoadSearchDraftUseCase _loadSearchDraftUseCase;
  final SaveSearchDraftUseCase _saveSearchDraftUseCase;
  final ToggleTransportTypeUseCase _toggleTransportTypeUseCase;
  final SwapSearchPointsUseCase _swapSearchPointsUseCase;
  final ValidateRouteSearchUseCase _validateRouteSearchUseCase;

  Future<void> loadDraft() async {
    add(const RouteSearchDraftRequested());
  }

  void setStart(SelectedPoint point) {
    add(RouteSearchStartChanged(point));
  }

  void setEnd(SelectedPoint point) {
    add(RouteSearchEndChanged(point));
  }

  void swap() {
    add(const RouteSearchSwapped());
  }

  void toggleTransportType(int type) {
    add(RouteSearchTransportTypeToggled(type));
  }

  SearchParams? validate() {
    final result = _validateRouteSearchUseCase(
      start: state.start,
      end: state.end,
      transportTypes: state.transportTypes,
    );
    add(const RouteSearchSubmitted());
    return result.params;
  }

  Future<void> _onDraftRequested(
    RouteSearchDraftRequested event,
    Emitter<RouteSearchState> emit,
  ) async {
    final draft = await _loadSearchDraftUseCase();
    emit(
      state.copyWith(
        start: draft.start,
        end: draft.end,
        transportTypes: draft.transportTypes,
        clearErrorText: true,
        clearValidParams: true,
      ),
    );
  }

  Future<void> _onStartChanged(
    RouteSearchStartChanged event,
    Emitter<RouteSearchState> emit,
  ) async {
    emit(
      state.copyWith(
        start: event.point,
        clearErrorText: true,
        clearValidParams: true,
      ),
    );
    await _saveDraft();
  }

  Future<void> _onEndChanged(
    RouteSearchEndChanged event,
    Emitter<RouteSearchState> emit,
  ) async {
    emit(
      state.copyWith(
        end: event.point,
        clearErrorText: true,
        clearValidParams: true,
      ),
    );
    await _saveDraft();
  }

  Future<void> _onSwapped(
    RouteSearchSwapped event,
    Emitter<RouteSearchState> emit,
  ) async {
    final swapped = _swapSearchPointsUseCase(
      start: state.start,
      end: state.end,
    );
    emit(
      state.copyWith(
        start: swapped.start,
        end: swapped.end,
        clearErrorText: true,
        clearValidParams: true,
      ),
    );
    await _saveDraft();
  }

  Future<void> _onTransportTypeToggled(
    RouteSearchTransportTypeToggled event,
    Emitter<RouteSearchState> emit,
  ) async {
    final next = _toggleTransportTypeUseCase(state.transportTypes, event.type);
    emit(
      state.copyWith(
        transportTypes: next,
        clearErrorText: true,
        clearValidParams: true,
      ),
    );
    await _saveDraft();
  }

  void _onSubmitted(
    RouteSearchSubmitted event,
    Emitter<RouteSearchState> emit,
  ) {
    final result = _validateRouteSearchUseCase(
      start: state.start,
      end: state.end,
      transportTypes: state.transportTypes,
    );
    if (result.params == null) {
      emit(
        state.copyWith(
          errorText: result.errorText,
          clearValidParams: true,
        ),
      );
      return;
    }
    emit(
      state.copyWith(
        errorText: result.errorText,
        validParams: result.params,
      ),
    );
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
