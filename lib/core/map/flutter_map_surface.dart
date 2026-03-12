import 'package:flutter/material.dart';
import 'package:flutter_dozor_city/core/domain/entities/app_lat_lng.dart';
import 'package:flutter_dozor_city/core/domain/entities/selected_point.dart';
import 'package:flutter_dozor_city/core/domain/entities/transport_route.dart';
import 'package:flutter_dozor_city/core/map/app_map_camera.dart';
import 'package:flutter_dozor_city/core/map/flutter_map_controller_adapter.dart';
import 'package:flutter_dozor_city/core/map/map_controller.dart';
import 'package:flutter_dozor_city/features/live_tracking/domain/entities/vehicle_entity.dart';
import 'package:flutter_map/flutter_map.dart' hide MapController;
import 'package:latlong2/latlong.dart' as ll;

class FlutterMapSurface extends StatelessWidget {
  const FlutterMapSurface({
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
  final VoidCallback? onCameraIdle;

  @override
  Widget build(BuildContext context) {
    final adapter = mapController as FlutterMapControllerAdapter;
    
    return ClipRRect(
      borderRadius: BorderRadius.circular(22),
      child: FlutterMap(
        mapController: adapter.mapController,
        options: MapOptions(
          initialCenter: ll.LatLng(
            mapController.camera.centerLat,
            mapController.camera.centerLng,
          ),
          initialZoom: mapController.camera.zoom,
          onMapReady: adapter.onMapReady,
          onPositionChanged: (position, hasGesture) {
            mapController.setCamera(
              AppMapCamera(
                centerLat: position.center.latitude,
                centerLng: position.center.longitude,
                zoom: position.zoom,
              ),
            );
          },
          onMapEvent: (event) {
            if (event is MapEventMoveEnd) {
              onCameraIdle?.call();
            }
          },
        ),
        children: [
          TileLayer(
            urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
            userAgentPackageName: 'ua.gov.dozor.city',
          ),
          PolylineLayer(
            polylines: _buildPolylines(),
          ),
          MarkerLayer(
            markers: _buildMarkers(),
          ),
        ],
      ),
    );
  }

  List<Marker> _buildMarkers() {
    final markers = vehicles
        .map(
          (vehicle) => Marker(
            point: ll.LatLng(vehicle.lat, vehicle.lng),
            width: 40,
            height: 40,
            child: Transform.rotate(
              angle: vehicle.azimuth.toDouble() * (3.1415926535897932 / 180),
              child: const Icon(
                Icons.navigation,
                color: Colors.blue,
                size: 30,
              ),
            ),
          ),
        )
        .toList();

    final start = previewStart;
    if (start != null) {
      markers.add(
        Marker(
          point: ll.LatLng(start.lat, start.lng),
          width: 40,
          height: 40,
          child: const Icon(Icons.location_on, color: Colors.green, size: 40),
        ),
      );
    }

    final end = previewEnd;
    if (end != null) {
      markers.add(
        Marker(
          point: ll.LatLng(end.lat, end.lng),
          width: 40,
          height: 40,
          child: const Icon(Icons.location_on, color: Colors.red, size: 40),
        ),
      );
    }

    return markers;
  }

  List<Polyline> _buildPolylines() {
    final polylines = routePolylines
        .expand(
          (route) => route.polylineSegments
              .where((segment) => segment.length > 1)
              .map(
                (segment) => Polyline(
                  points: segment
                      .map((point) => ll.LatLng(point.lat, point.lng))
                      .toList(growable: false),
                  color: Color(route.lineColorValue),
                  strokeWidth: 5,
                ),
              ),
        )
        .toList(growable: false);
    if (previewGeometry.isNotEmpty) {
      return [
        ...polylines,
        Polyline(
          points: previewGeometry
              .map((point) => ll.LatLng(point.lat, point.lng))
              .toList(),
          color: const Color(0xFFFCB813),
          strokeWidth: 6,
        ),
      ];
    }
    
    final start = previewStart;
    final end = previewEnd;
    if (start != null && end != null) {
      return [
        ...polylines,
        Polyline(
          points: [
            ll.LatLng(start.lat, start.lng),
            ll.LatLng(end.lat, end.lng),
          ],
          color: const Color(0xFFFCB813),
          strokeWidth: 6,
        ),
      ];
    }

    return polylines;
  }
}
