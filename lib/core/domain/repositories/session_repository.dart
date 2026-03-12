import 'package:flutter_dozor_city/core/map/app_map_camera.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_dozor_city/core/domain/entities/city.dart';

abstract class SessionRepository extends ChangeNotifier {
  City? get selectedCity;
  bool get hasSelectedCity;
  Future<void> setSelectedCity(City city);
  Future<int?> getRoutesCacheHash(String cityId);
  Future<void> setRoutesCacheHash(String cityId, int hash);
  Future<AppMapCamera?> getMapCamera(String cityId);
  Future<void> setMapCamera(String cityId, AppMapCamera camera);
  Future<bool> getUiFlag(String key);
  Future<void> setUiFlag(String key, bool value);
}
