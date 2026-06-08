import 'package:flutter_dozor_city/core/domain/entities/city.dart';
import 'package:flutter_dozor_city/core/domain/entities/selected_map_routes.dart';
import 'package:flutter_dozor_city/core/domain/repositories/session_repository.dart';
import 'package:flutter_dozor_city/core/map/app_map_camera.dart';
import 'package:hive/hive.dart';
import 'package:flutter_dozor_city/core/domain/repositories/city_session_repository.dart';
import 'package:flutter_dozor_city/core/domain/repositories/map_camera_repository.dart';
import 'package:flutter_dozor_city/core/domain/repositories/route_cache_metadata_repository.dart';
import 'package:flutter_dozor_city/core/domain/repositories/ui_flags_repository.dart';

class HiveSessionRepository extends SessionRepository
    implements
        CitySessionRepository,
        RouteCacheMetadataRepository,
        MapCameraRepository,
        UiFlagsRepository {
  HiveSessionRepository({required Box<dynamic> box})
    : _box = box,
      _selectedCity = _readCity(box.get(_selectedCityKey));

  static const _selectedCityKey = 'selected_city';
  static const _mapLanguageKey = 'map_language';

  final Box<dynamic> _box;
  City? _selectedCity;

  @override
  bool get hasSelectedCity => _selectedCity != null;

  @override
  Future<int?> getRoutesCacheHash(String cityId) async {
    final raw = _box.get(_routesCacheHashKey(cityId));
    if (raw is num) {
      return raw.toInt();
    }
    return null;
  }

  @override
  Future<SelectedMapRoutes?> getSelectedMapRoutes(String cityId) async {
    final rawTransportType = _box.get(_selectedTransportTypeKey(cityId));
    if (rawTransportType is! num) {
      return null;
    }
    final transportType = rawTransportType.toInt();
    final rawRouteIds = _box.get(_selectedRouteIdsKey(cityId, transportType));
    final rawActiveRouteId = _box.get(_activeRouteIdKey(cityId, transportType));
    return SelectedMapRoutes(
      transportType: transportType,
      selectedRouteIds: rawRouteIds is List
          ? rawRouteIds.whereType<String>().toList(growable: false)
          : const [],
      activeRouteId: rawActiveRouteId is String ? rawActiveRouteId : null,
    );
  }

  @override
  City? get selectedCity => _selectedCity;

  @override
  Future<AppMapCamera?> getMapCamera(String cityId) async {
    final raw = _box.get(_mapCameraKey(cityId));
    if (raw is! Map) {
      return null;
    }
    return AppMapCamera(
      centerLat: (raw['centerLat'] as num).toDouble(),
      centerLng: (raw['centerLng'] as num).toDouble(),
      zoom: (raw['zoom'] as num).toDouble(),
    );
  }

  @override
  Future<bool> getUiFlag(String key) async {
    final raw = _box.get(_uiFlagKey(key));
    if (raw is bool) {
      return raw;
    }
    return false;
  }

  @override
  Future<void> setSelectedCity(City city) async {
    await _box.put(_selectedCityKey, <String, dynamic>{
      'id': city.id,
      'name': city.name,
      'region': city.region,
      'centerLat': city.centerLat,
      'centerLng': city.centerLng,
      'zoom': city.zoom,
    });
    _selectedCity = city;
    notifyListeners();
  }

  @override
  Future<void> setRoutesCacheHash(String cityId, int hash) async {
    await _box.put(_routesCacheHashKey(cityId), hash);
  }

  @override
  Future<void> setSelectedMapRoutes(
    String cityId,
    SelectedMapRoutes selectedMapRoutes,
  ) async {
    await _box.put(
      _selectedTransportTypeKey(cityId),
      selectedMapRoutes.transportType,
    );
    await _box.put(
      _selectedRouteIdsKey(cityId, selectedMapRoutes.transportType),
      selectedMapRoutes.selectedRouteIds,
    );
    await _box.put(
      _activeRouteIdKey(cityId, selectedMapRoutes.transportType),
      selectedMapRoutes.activeRouteId,
    );
  }

  @override
  Future<void> setMapCamera(String cityId, AppMapCamera camera) async {
    await _box.put(_mapCameraKey(cityId), <String, dynamic>{
      'centerLat': camera.centerLat,
      'centerLng': camera.centerLng,
      'zoom': camera.zoom,
    });
  }

  @override
  Future<void> setUiFlag(String key, bool value) async {
    await _box.put(_uiFlagKey(key), value);
  }

  @override
  Future<String?> getMapLanguage() async {
    final raw = _box.get(_mapLanguageKey);
    final value = raw is String ? raw.trim() : '';
    return value.isEmpty ? null : value;
  }

  @override
  Future<void> setMapLanguage(String languageCode) async {
    final value = languageCode.trim();
    if (value.isEmpty) {
      await _box.delete(_mapLanguageKey);
      return;
    }
    await _box.put(_mapLanguageKey, value);
  }

  static City? _readCity(dynamic raw) {
    if (raw is! Map) {
      return null;
    }
    return City(
      id: raw['id'] as String,
      name: raw['name'] as String,
      region: raw['region'] as String,
      centerLat: (raw['centerLat'] as num).toDouble(),
      centerLng: (raw['centerLng'] as num).toDouble(),
      zoom: (raw['zoom'] as num).toDouble(),
    );
  }

  static String _routesCacheHashKey(String cityId) =>
      'routes_cache_hash_v2:$cityId';
  static String _selectedTransportTypeKey(String cityId) =>
      'selected_transport_type:$cityId';
  static String _selectedRouteIdsKey(String cityId, int transportType) =>
      'selected_route_ids:$cityId:$transportType';
  static String _activeRouteIdKey(String cityId, int transportType) =>
      'active_route_id:$cityId:$transportType';
  static String _mapCameraKey(String cityId) => 'map_camera:$cityId';
  static String _uiFlagKey(String key) => 'ui_flag:$key';
}
