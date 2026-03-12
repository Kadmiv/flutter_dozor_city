import 'package:flutter_dozor_city/core/domain/entities/selected_point.dart';
import 'package:flutter_dozor_city/core/domain/repositories/search_repository.dart';

class SearchAddressSuggestionsUseCase {
  const SearchAddressSuggestionsUseCase(this._searchRepository);

  final SearchRepository _searchRepository;

  Future<List<SelectedPoint>> call(String query) async {
    final normalized = query.trim();
    if (normalized.isEmpty) {
      return const [];
    }
    return _searchRepository.searchAddressSuggestions(normalized);
  }
}
