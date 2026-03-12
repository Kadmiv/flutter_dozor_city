import 'package:flutter/foundation.dart';
import 'package:flutter_dozor_city/core/domain/entities/route_result.dart';

abstract class StoredRoutesRepository extends ChangeNotifier {
  Future<List<RouteResult>> getStoredRoutes();
  Future<void> save(RouteResult route);
  Future<void> remove(String routeId);
  Future<bool> contains(String routeId);
}
