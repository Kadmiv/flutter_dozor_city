import 'package:flutter_dozor_city/core/map/app_map_camera.dart';

abstract class MapCameraRepository {
  Future<AppMapCamera?> getMapCamera(String cityId);
  Future<void> setMapCamera(String cityId, AppMapCamera camera);
}
