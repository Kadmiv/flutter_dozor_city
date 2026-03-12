import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_dozor_city/core/domain/entities/selected_point.dart';
import 'package:flutter_dozor_city/core/domain/repositories/search_draft_repository.dart';
import 'package:flutter_dozor_city/features/route_search/domain/usecases/load_search_draft_use_case.dart';
import 'package:flutter_dozor_city/features/route_search/domain/usecases/save_search_draft_use_case.dart';
import 'package:flutter_dozor_city/features/route_search/domain/usecases/swap_search_points_use_case.dart';
import 'package:flutter_dozor_city/features/route_search/domain/usecases/toggle_transport_type_use_case.dart';
import 'package:flutter_dozor_city/features/route_search/domain/usecases/validate_route_search_use_case.dart';
import 'package:flutter_dozor_city/features/route_search/presentation/bloc/route_search_cubit.dart';
import 'package:flutter_dozor_city/features/route_search/presentation/pages/route_search_page.dart';

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
  RouteSearchCubit buildCubit() {
    final repository = _InMemorySearchDraftRepository();
    return RouteSearchCubit(
      loadSearchDraftUseCase: LoadSearchDraftUseCase(repository),
      saveSearchDraftUseCase: SaveSearchDraftUseCase(repository),
      toggleTransportTypeUseCase: const ToggleTransportTypeUseCase(),
      swapSearchPointsUseCase: const SwapSearchPointsUseCase(),
      validateRouteSearchUseCase: const ValidateRouteSearchUseCase(),
    );
  }

  group('RouteSearchPage', () {
    testWidgets('renders compact legacy search layout', (tester) async {
      final cubit = buildCubit();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: RouteSearchPage(cubit: cubit),
          ),
        ),
      );
      await tester.pump();

      expect(find.text('Від'), findsOneWidget);
      expect(find.text('До'), findsOneWidget);
      expect(find.byIcon(Icons.swap_vert), findsOneWidget);
      expect(find.byIcon(Icons.search), findsOneWidget);
      expect(find.byIcon(Icons.directions_bus), findsOneWidget);
      expect(find.byIcon(Icons.tram), findsOneWidget);
      expect(find.byIcon(Icons.electric_bolt), findsWidgets);
    });

    testWidgets('swap button exchanges selected points', (tester) async {
      final cubit = buildCubit();
      const start = SelectedPoint(
        label: 'Майдан Соборний',
        lat: 50.254,
        lng: 28.658,
        source: SelectedPointSource.zone,
      );
      const end = SelectedPoint(
        label: 'Автовокзал',
        lat: 50.271,
        lng: 28.676,
        source: SelectedPointSource.address,
      );
      cubit.setStart(start);
      cubit.setEnd(end);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: RouteSearchPage(cubit: cubit),
          ),
        ),
      );
      await tester.pump();

      expect(find.text('Майдан Соборний'), findsOneWidget);
      expect(find.text('Автовокзал'), findsOneWidget);

      await tester.tap(find.byIcon(Icons.swap_vert));
      await tester.pump();

      final labels = find.text('Автовокзал');
      expect(labels, findsOneWidget);
      expect(cubit.state.start?.label, 'Автовокзал');
      expect(cubit.state.end?.label, 'Майдан Соборний');
    });

    testWidgets('search button shows validation error when points are missing',
        (tester) async {
      final cubit = buildCubit();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: RouteSearchPage(cubit: cubit),
          ),
        ),
      );
      await tester.pump();

      await tester.tap(find.byIcon(Icons.search));
      await tester.pump();

      expect(find.text('Заповніть точки Від та До'), findsOneWidget);
    });
  });
}
