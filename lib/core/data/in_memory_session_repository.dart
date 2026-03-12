import 'package:flutter_dozor_city/core/domain/entities/city.dart';
import 'package:flutter_dozor_city/core/domain/repositories/session_repository.dart';
import 'package:flutter_dozor_city/core/map/app_map_camera.dart';

class InMemorySessionRepository extends SessionRepository {
  City? _selectedCity;
  final Map<String, int> _routesHashes = {};
  final Map<String, AppMapCamera> _mapCameras = {};
  final Map<String, bool> _uiFlags = {};

  @override
  bool get hasSelectedCity => _selectedCity != null;

  @override
  Future<int?> getRoutesCacheHash(String cityId) async => _routesHashes[cityId];

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
  Future<void> setMapCamera(String cityId, AppMapCamera camera) async {
    _mapCameras[cityId] = camera;
  }

  @override
  Future<void> setUiFlag(String key, bool value) async {
    _uiFlags[key] = value;
  }
}
