import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_dozor_city/core/domain/entities/selected_point.dart';
import 'package:flutter_dozor_city/core/domain/repositories/search_draft_repository.dart';
import 'package:flutter_dozor_city/features/route_search/domain/usecases/load_search_draft_use_case.dart';
import 'package:flutter_dozor_city/features/route_search/domain/usecases/save_search_draft_use_case.dart';
import 'package:flutter_dozor_city/features/route_search/domain/usecases/swap_search_points_use_case.dart';
import 'package:flutter_dozor_city/features/route_search/domain/usecases/toggle_transport_type_use_case.dart';
import 'package:flutter_dozor_city/features/route_search/domain/usecases/validate_route_search_use_case.dart';
import 'package:flutter_dozor_city/features/route_search/presentation/bloc/route_search_cubit.dart';

class _InMemorySearchDraftRepository implements SearchDraftRepository {
  SearchDraft _draft = const SearchDraft();

  @override
  Future<void> clearDraft() async {
    _draft = const SearchDraft();
  }

  @override
  Future<SearchDraft> loadDraft() async => _draft;

  @override
  Future<void> saveDraft(SearchDraft draft) async {
    _draft = draft;
  }
}

void main() {
  group('RouteSearchBloc', () {
    test('returns validation error when points are missing', () async {
      final draftRepository = _InMemorySearchDraftRepository();
      final cubit = RouteSearchBloc(
        loadSearchDraftUseCase: LoadSearchDraftUseCase(draftRepository),
        saveSearchDraftUseCase: SaveSearchDraftUseCase(draftRepository),
        toggleTransportTypeUseCase: const ToggleTransportTypeUseCase(),
        swapSearchPointsUseCase: const SwapSearchPointsUseCase(),
        validateRouteSearchUseCase: const ValidateRouteSearchUseCase(),
      );

      final result = cubit.validate();
      await Future<void>.delayed(Duration.zero);

      expect(result, isNull);
      expect(cubit.state.errorText, 'Заповніть точки Від та До');
    });

    test('builds params when form is complete', () async {
      final draftRepository = _InMemorySearchDraftRepository();
      final cubit = RouteSearchBloc(
        loadSearchDraftUseCase: LoadSearchDraftUseCase(draftRepository),
        saveSearchDraftUseCase: SaveSearchDraftUseCase(draftRepository),
        toggleTransportTypeUseCase: const ToggleTransportTypeUseCase(),
        swapSearchPointsUseCase: const SwapSearchPointsUseCase(),
        validateRouteSearchUseCase: const ValidateRouteSearchUseCase(),
      );
      const start = SelectedPoint(
        label: 'Майдан Соборний',
        lat: 50.254,
        lng: 28.658,
        source: SelectedPointSource.zone,
        zoneId: 101,
      );
      const end = SelectedPoint(
        label: 'Автовокзал',
        lat: 50.271,
        lng: 28.676,
        source: SelectedPointSource.address,
      );

      cubit.setStart(start);
      cubit.setEnd(end);
      await Future<void>.delayed(Duration.zero);
      final result = cubit.validate();
      await Future<void>.delayed(Duration.zero);

      expect(result, isNotNull);
      expect(result!.start, start);
      expect(result.end, end);
      expect(result.transportTypes, {0});
      expect(cubit.state.errorText, isNull);
    });
  });
}
