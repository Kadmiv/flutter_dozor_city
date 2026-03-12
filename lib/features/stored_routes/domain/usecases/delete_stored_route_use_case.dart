import 'package:flutter_dozor_city/core/domain/repositories/stored_routes_repository.dart';

class DeleteStoredRouteUseCase {
  const DeleteStoredRouteUseCase(this._storedRoutesRepository);

  final StoredRoutesRepository _storedRoutesRepository;

  Future<void> call(String routeId) {
    return _storedRoutesRepository.remove(routeId);
  }
}
