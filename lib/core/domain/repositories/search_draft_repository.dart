import 'package:flutter_dozor_city/core/domain/entities/selected_point.dart';

class SearchDraft {
  const SearchDraft({
    this.start,
    this.end,
    this.transportTypes = const {0},
  });

  final SelectedPoint? start;
  final SelectedPoint? end;
  final Set<int> transportTypes;
}

abstract class SearchDraftRepository {
  Future<SearchDraft> loadDraft();
  Future<void> saveDraft(SearchDraft draft);
  Future<void> clearDraft();
}
