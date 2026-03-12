import 'package:flutter_dozor_city/core/map/app_map_camera.dart';
import 'package:flutter_dozor_city/core/map/map_marker_data.dart';

abstract class MapController {
  AppMapCamera get camera;
  Future<void> setCamera(AppMapCamera camera);
  List<MapMarkerData> get markers;
  Future<void> setMarkers(List<MapMarkerData> markers);
  void cacheCamera(AppMapCamera camera);
}
