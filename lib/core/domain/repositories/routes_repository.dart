import 'package:flutter_dozor_city/core/domain/entities/route_zone.dart';
import 'package:flutter_dozor_city/core/domain/entities/transport_route.dart';

abstract class RoutesRepository {
  Future<List<TransportRoute>> getRoutesByType({
    required String cityId,
    required int transportType,
  });
  Future<List<RouteZone>> getRouteZones(String routeId);
}
