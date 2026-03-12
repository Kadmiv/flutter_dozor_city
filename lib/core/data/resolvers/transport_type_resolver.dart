import 'package:flutter_dozor_city/core/data/models/json_route_model.dart';

abstract final class TransportTypeResolver {
  static int resolve(JsonRouteModel route) {
    if (route.transportType != null) {
      return route.transportType!;
    }

    final haystack = [
      route.shortName,
      route.info,
      ...route.names,
    ].join(' ').toLowerCase();

    if (_matchesAny(haystack, const ['трол', 'trolley'])) {
      return 1;
    }
    if (_matchesAny(haystack, const ['трам', 'tram'])) {
      return 2;
    }
    if (_matchesAny(haystack, const ['комун', 'коммун', 'municipal'])) {
      return 3;
    }
    if (_matchesAny(haystack, const ['приміськ', 'пригород'])) {
      return 4;
    }
    if (_matchesAny(haystack, const ['мтг'])) {
      return 5;
    }

    return 0;
  }

  static bool _matchesAny(String haystack, List<String> needles) {
    return needles.any(haystack.contains);
  }
}
