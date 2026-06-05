import 'package:flutter_dozor_city/core/domain/entities/search_params.dart';
import 'package:flutter_dozor_city/core/domain/entities/transport_route.dart';

class RoutePreviewArgs {
  const RoutePreviewArgs({
    required this.route,
    this.params,
  });

  final TransportRoute route;
  final SearchParams? params;
}

class RouteResultsArgs {
  const RouteResultsArgs(this.params);

  final SearchParams params;
}
