import 'package:flutter_dozor_city/core/domain/entities/app_lat_lng.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dozor_city/core/domain/entities/selected_point.dart';
import 'package:flutter_dozor_city/core/domain/entities/transport_route.dart';
import 'package:flutter_dozor_city/core/map/app_map_camera.dart';
import 'package:flutter_dozor_city/core/map/map_controller.dart';
import 'package:flutter_dozor_city/core/map/google_map_controller_adapter.dart';
import 'package:flutter_dozor_city/features/live_tracking/domain/entities/vehicle_entity.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart' as gmaps;

class GoogleMapSurface extends StatelessWidget {
  const GoogleMapSurface({
    super.key,
    required this.mapController,
    required this.vehicles,
    this.routePolylines = const [],
    this.previewGeometry = const [],
    this.previewStart,
    this.previewEnd,
    this.onCameraIdle,
  });

  final MapController mapController;
  final List<VehicleEntity> vehicles;
  final List<TransportRoute> routePolylines;
  final List<AppLatLng> previewGeometry;
  final SelectedPoint? previewStart;
  final SelectedPoint? previewEnd;
  final ValueChanged<gmaps.CameraPosition>? onCameraIdle;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(22),
      child: gmaps.GoogleMap(
        initialCameraPosition: gmaps.CameraPosition(
          target: gmaps.LatLng(
            mapController.camera.centerLat,
            mapController.camera.centerLng,
          ),
          zoom: mapController.camera.zoom,
        ),
        myLocationButtonEnabled: false,
        zoomControlsEnabled: false,
        mapToolbarEnabled: false,
        onMapCreated: (controller) => (mapController as GoogleMapControllerAdapter).bind(controller),
        onCameraIdle: () => onCameraIdle?.call(
          gmaps.CameraPosition(
            target: gmaps.LatLng(
              mapController.camera.centerLat,
              mapController.camera.centerLng,
            ),
            zoom: mapController.camera.zoom,
          ),
        ),
        onCameraMove: (position) {
          mapController.cacheCamera(
            AppMapCamera(
              centerLat: position.target.latitude,
              centerLng: position.target.longitude,
              zoom: position.zoom,
            ),
          );
        },
        markers: _buildMarkers(),
        polylines: _buildPolylines(),
      ),
    );
  }

  Set<gmaps.Marker> _buildMarkers() {
    final markers = vehicles
        .map(
          (vehicle) => gmaps.Marker(
            markerId: gmaps.MarkerId(vehicle.id),
            position: gmaps.LatLng(vehicle.lat, vehicle.lng),
            rotation: vehicle.azimuth.toDouble(),
            anchor: const Offset(0.5, 0.5),
            infoWindow: gmaps.InfoWindow(
              title: 'Маршрут ${vehicle.routeShortName} • ${vehicle.govNumber}',
              snippet: '${vehicle.routeTitle} • ${vehicle.speed} км/год',
            ),
          ),
        )
        .toSet();
    final start = previewStart;
    if (start != null) {
      markers.add(
        gmaps.Marker(
          markerId: const gmaps.MarkerId('preview-start'),
          position: gmaps.LatLng(start.lat, start.lng),
          icon: gmaps.BitmapDescriptor.defaultMarkerWithHue(
            gmaps.BitmapDescriptor.hueGreen,
          ),
          infoWindow: gmaps.InfoWindow(
            title: 'Старт',
            snippet: start.label,
          ),
        ),
      );
    }
    final end = previewEnd;
    if (end != null) {
      markers.add(
        gmaps.Marker(
          markerId: const gmaps.MarkerId('preview-end'),
          position: gmaps.LatLng(end.lat, end.lng),
          icon: gmaps.BitmapDescriptor.defaultMarkerWithHue(
            gmaps.BitmapDescriptor.hueRed,
          ),
          infoWindow: gmaps.InfoWindow(
            title: 'Фініш',
            snippet: end.label,
          ),
        ),
      );
    }
    return markers;
  }

  Set<gmaps.Polyline> _buildPolylines() {
    final polylines = routePolylines
        .expand(
          (route) => route.polylineSegments.indexed
              .where((entry) => entry.$2.length > 1)
              .map(
                (entry) => gmaps.Polyline(
                  polylineId: gmaps.PolylineId(
                    'route-${route.id}-${entry.$1}',
                  ),
                  points: entry.$2
                      .map((point) => gmaps.LatLng(point.lat, point.lng))
                      .toList(growable: false),
                  color: Color(route.lineColorValue),
                  width: 5,
                ),
              ),
        )
        .toSet();
    final start = previewStart;
    final end = previewEnd;
    if (previewGeometry.isNotEmpty) {
      polylines.add(
        gmaps.Polyline(
          polylineId: const gmaps.PolylineId('preview-line'),
          points: previewGeometry
              .map((point) => gmaps.LatLng(point.lat, point.lng))
              .toList(growable: false),
          color: const Color(0xFFFCB813),
          width: 6,
        ),
      );
      return polylines;
    }
    if (start == null || end == null) {
      return polylines;
    }
    polylines.add(
      gmaps.Polyline(
        polylineId: const gmaps.PolylineId('preview-line'),
        points: [
          gmaps.LatLng(start.lat, start.lng),
          gmaps.LatLng(end.lat, end.lng),
        ],
        color: const Color(0xFFFCB813),
        width: 6,
      ),
    );
    return polylines;
  }
}
