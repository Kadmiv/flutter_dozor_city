import 'package:flutter/foundation.dart';
import 'package:flutter_dozor_city/core/domain/repositories/stored_routes_repository.dart';

class WatchStoredRoutesUseCase {
  const WatchStoredRoutesUseCase(this._repository);
  final StoredRoutesRepository _repository;

  void addListener(VoidCallback listener) {
    _repository.addListener(listener);
  }

  void removeListener(VoidCallback listener) {
    _repository.removeListener(listener);
  }
}
