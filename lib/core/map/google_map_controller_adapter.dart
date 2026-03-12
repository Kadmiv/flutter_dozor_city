import 'package:flutter_dozor_city/core/map/app_map_camera.dart';
import 'package:flutter_dozor_city/core/map/map_controller.dart';
import 'package:flutter_dozor_city/core/map/map_marker_data.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart' as gmaps;

class GoogleMapControllerAdapter implements MapController {
  AppMapCamera _camera = const AppMapCamera(
    centerLat: 50.25465,
    centerLng: 28.65867,
    zoom: 12.5,
  );
  List<MapMarkerData> _markers = const [];
  gmaps.GoogleMapController? _controller;

  @override
  AppMapCamera get camera => _camera;

  @override
  List<MapMarkerData> get markers => _markers;

  void bind(gmaps.GoogleMapController controller) {
    _controller = controller;
  }

  @override
  void cacheCamera(AppMapCamera camera) {
    _camera = camera;
  }

  void unbind() {
    _controller = null;
  }

  @override
  Future<void> setCamera(AppMapCamera camera) async {
    _camera = camera;
    await _controller?.animateCamera(
      gmaps.CameraUpdate.newCameraPosition(
        gmaps.CameraPosition(
          target: gmaps.LatLng(camera.centerLat, camera.centerLng),
          zoom: camera.zoom,
        ),
      ),
    );
  }

  @override
  Future<void> setMarkers(List<MapMarkerData> markers) async {
    _markers = markers;
  }
}
