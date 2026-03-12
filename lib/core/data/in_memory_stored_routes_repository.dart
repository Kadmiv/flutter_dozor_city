import 'package:flutter/foundation.dart';
import 'package:flutter_dozor_city/core/domain/entities/route_result.dart';
import 'package:flutter_dozor_city/core/domain/repositories/stored_routes_repository.dart';

class InMemoryStoredRoutesRepository extends ChangeNotifier
    implements StoredRoutesRepository {
  final Map<String, RouteResult> _storage = {};

  @override
  Future<bool> contains(String routeId) async => _storage.containsKey(routeId);

  @override
  Future<List<RouteResult>> getStoredRoutes() async {
    return _storage.values.toList(growable: false);
  }

  @override
  Future<void> remove(String routeId) async {
    _storage.remove(routeId);
    notifyListeners();
  }

  @override
  Future<void> save(RouteResult route) async {
    _storage[route.id] = route.copyWith(isStored: true);
    notifyListeners();
  }
}
