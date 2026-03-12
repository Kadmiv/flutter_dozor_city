import 'package:flutter_dozor_city/core/domain/repositories/search_draft_repository.dart';

class SaveSearchDraftUseCase {
  const SaveSearchDraftUseCase(this._searchDraftRepository);

  final SearchDraftRepository _searchDraftRepository;

  Future<void> call(SearchDraft draft) {
    return _searchDraftRepository.saveDraft(draft);
  }
}
