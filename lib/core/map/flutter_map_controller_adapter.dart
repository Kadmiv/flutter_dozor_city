import 'package:flutter_dozor_city/core/map/app_map_camera.dart';
import 'package:flutter_dozor_city/core/map/map_controller.dart';
import 'package:flutter_dozor_city/core/map/map_marker_data.dart';
import 'package:flutter_map/flutter_map.dart' as fm;
import 'package:latlong2/latlong.dart' as ll;

class FlutterMapControllerAdapter implements MapController {
  final fm.MapController mapController = fm.MapController();
  
  AppMapCamera _camera = const AppMapCamera(
    centerLat: 50.25465,
    centerLng: 28.65867,
    zoom: 12.5,
  );
  List<MapMarkerData> _markers = const [];
  bool _isMapReady = false;
  AppMapCamera? _pendingCamera;

  @override
  AppMapCamera get camera => _camera;

  @override
  List<MapMarkerData> get markers => _markers;

  void onMapReady() {
    _isMapReady = true;
    final pending = _pendingCamera;
    if (pending != null) {
      _pendingCamera = null;
      setCamera(pending);
    }
  }

  @override
  Future<void> setCamera(AppMapCamera camera) async {
    _camera = camera;
    if (_isMapReady) {
      mapController.move(
        ll.LatLng(camera.centerLat, camera.centerLng),
        camera.zoom,
      );
    } else {
      _pendingCamera = camera;
    }
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
