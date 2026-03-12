import 'package:flutter_dozor_city/core/domain/entities/route_result.dart';
import 'package:flutter_dozor_city/core/domain/repositories/stored_routes_repository.dart';

class ToggleStoredRouteUseCase {
  const ToggleStoredRouteUseCase(this._storedRoutesRepository);

  final StoredRoutesRepository _storedRoutesRepository;

  Future<bool> call(RouteResult route) async {
    if (route.isStored) {
      await _storedRoutesRepository.remove(route.id);
      return false;
    }
    await _storedRoutesRepository.save(route);
    return true;
  }
}
