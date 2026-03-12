import 'package:flutter_dozor_city/core/domain/entities/selected_point.dart';
import 'package:flutter_dozor_city/core/domain/repositories/search_repository.dart';

class GetCurrentLocationUseCase {
  const GetCurrentLocationUseCase(this._searchRepository);

  final SearchRepository _searchRepository;

  Future<SelectedPoint> call() {
    return _searchRepository.getCurrentLocation();
  }
}
