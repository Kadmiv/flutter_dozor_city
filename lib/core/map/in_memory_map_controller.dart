import 'package:flutter_dozor_city/core/map/app_map_camera.dart';
import 'package:flutter_dozor_city/core/map/map_controller.dart';
import 'package:flutter_dozor_city/core/map/map_marker_data.dart';

class InMemoryMapController implements MapController {
  AppMapCamera _camera = const AppMapCamera(
    centerLat: 0.0,
    centerLng: 0.0,
    zoom: 12.0,
  );
  List<MapMarkerData> _markers = const [];

  @override
  AppMapCamera get camera => _camera;

  @override
  List<MapMarkerData> get markers => _markers;

  @override
  Future<void> setCamera(AppMapCamera camera) async {
    _camera = camera;
  }

  @override
  Future<void> setMarkers(List<MapMarkerData> markers) async {
    _markers = markers;
  }

  @override
  void cacheCamera(AppMapCamera camera) {
    _camera = camera;
  }
}
