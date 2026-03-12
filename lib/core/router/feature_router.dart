import 'package:go_router/go_router.dart';

abstract class FeatureRouter {
  const FeatureRouter();

  List<RouteBase> get routes;
}
