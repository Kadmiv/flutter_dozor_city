import 'package:flutter_dozor_city/core/domain/entities/route_result.dart';
import 'package:flutter_dozor_city/core/domain/repositories/stored_routes_repository.dart';

class GetStoredRoutesUseCase {
  const GetStoredRoutesUseCase(this._storedRoutesRepository);

  final StoredRoutesRepository _storedRoutesRepository;

  Future<List<RouteResult>> call() {
    return _storedRoutesRepository.getStoredRoutes();
  }
}
