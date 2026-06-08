import 'package:flutter/foundation.dart';
import 'package:flutter_dozor_city/core/domain/repositories/city_session_repository.dart';
import 'package:flutter_dozor_city/core/domain/entities/selected_map_routes.dart';
import 'package:flutter_dozor_city/core/domain/repositories/map_camera_repository.dart';
import 'package:flutter_dozor_city/core/domain/repositories/ui_flags_repository.dart';

abstract class SessionRepository extends ChangeNotifier
    implements CitySessionRepository, MapCameraRepository, UiFlagsRepository {
  Future<int?> getRoutesCacheHash(String cityId);
  Future<void> setRoutesCacheHash(String cityId, int hash);
  Future<SelectedMapRoutes?> getSelectedMapRoutes(String cityId);
  Future<void> setSelectedMapRoutes(
    String cityId,
    SelectedMapRoutes selectedMapRoutes,
  );
  Future<String?> getMapLanguage();
  Future<void> setMapLanguage(String languageCode);
}
