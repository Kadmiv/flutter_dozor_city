import 'package:flutter_dozor_city/core/domain/repositories/search_draft_repository.dart';

class LoadSearchDraftUseCase {
  const LoadSearchDraftUseCase(this._searchDraftRepository);

  final SearchDraftRepository _searchDraftRepository;

  Future<SearchDraft> call() {
    return _searchDraftRepository.loadDraft();
  }
}
