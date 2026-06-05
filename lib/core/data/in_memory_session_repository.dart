import 'package:flutter_dozor_city/core/domain/entities/city.dart';
import 'package:flutter_dozor_city/core/domain/entities/selected_map_routes.dart';
import 'package:flutter_dozor_city/core/domain/repositories/session_repository.dart';
import 'package:flutter_dozor_city/core/map/app_map_camera.dart';

import 'package:flutter_dozor_city/core/domain/repositories/city_session_repository.dart';
import 'package:flutter_dozor_city/core/domain/repositories/map_camera_repository.dart';
import 'package:flutter_dozor_city/core/domain/repositories/route_cache_metadata_repository.dart';
import 'package:flutter_dozor_city/core/domain/repositories/ui_flags_repository.dart';

class InMemorySessionRepository extends SessionRepository implements CitySessionRepository, RouteCacheMetadataRepository, MapCameraRepository, UiFlagsRepository {
  City? _selectedCity;
  final Map<String, int> _routesHashes = {};
  final Map<String, AppMapCamera> _mapCameras = {};
  final Map<String, bool> _uiFlags = {};
  final Map<String, SelectedMapRoutes> _selectedMapRoutes = {};

  @override
  bool get hasSelectedCity => _selectedCity != null;

  @override
  Future<int?> getRoutesCacheHash(String cityId) async => _routesHashes[cityId];

  @override
  Future<SelectedMapRoutes?> getSelectedMapRoutes(String cityId) async =>
      _selectedMapRoutes[cityId];

  @override
  City? get selectedCity => _selectedCity;

  @override
  Future<AppMapCamera?> getMapCamera(String cityId) async => _mapCameras[cityId];

  @override
  Future<bool> getUiFlag(String key) async => _uiFlags[key] ?? false;

  @override
  Future<void> setSelectedCity(City city) async {
    _selectedCity = city;
    notifyListeners();
  }

  @override
  Future<void> setRoutesCacheHash(String cityId, int hash) async {
    _routesHashes[cityId] = hash;
  }

  @override
  Future<void> setSelectedMapRoutes(
    String cityId,
    SelectedMapRoutes selectedMapRoutes,
  ) async {
    _selectedMapRoutes[cityId] = selectedMapRoutes;
  }

  @override
  Future<void> setMapCamera(String cityId, AppMapCamera camera) async {
    _mapCameras[cityId] = camera;
  }

  @override
  Future<void> setUiFlag(String key, bool value) async {
    _uiFlags[key] = value;
  }
}
