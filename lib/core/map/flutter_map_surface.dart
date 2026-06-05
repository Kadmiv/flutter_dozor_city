import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_dozor_city/core/domain/entities/app_lat_lng.dart';
import 'package:flutter_dozor_city/core/domain/entities/selected_point.dart';
import 'package:flutter_dozor_city/core/domain/entities/transport_route.dart';
import 'package:flutter_dozor_city/core/map/app_map_camera.dart';
import 'package:flutter_dozor_city/core/map/flutter_map_controller_adapter.dart';
import 'package:flutter_dozor_city/core/map/map_controller.dart';
import 'package:flutter_dozor_city/core/domain/entities/vehicle.dart';
import 'package:flutter_dozor_city/features/live_tracking/domain/entities/animated_vehicle.dart';
import 'package:flutter_dozor_city/features/live_tracking/presentation/widgets/vehicle_marker_widget.dart';
import 'package:flutter_map/flutter_map.dart' hide MapController;
import 'package:latlong2/latlong.dart' as ll;

class FlutterMapSurface extends StatefulWidget {
  const FlutterMapSurface({
    super.key,
    required this.mapController,
    required this.vehicles,
    required this.selectedRoutesCount,
    required this.routeColorsById,
    this.onVehicleTap,
    this.routePolylines = const [],
    this.previewGeometry = const [],
    this.previewStart,
    this.previewEnd,
    this.onCameraIdle,
  });

  final MapController mapController;
  final List<AnimatedVehicle> vehicles;
  final int selectedRoutesCount;
  final Map<String, int> routeColorsById;
  final ValueChanged<Vehicle>? onVehicleTap;
  final List<TransportRoute> routePolylines;
  final List<AppLatLng> previewGeometry;
  final SelectedPoint? previewStart;
  final SelectedPoint? previewEnd;
  final VoidCallback? onCameraIdle;

  @override
  State<FlutterMapSurface> createState() => _FlutterMapSurfaceState();
}

class _FlutterMapSurfaceState extends State<FlutterMapSurface> {
  Timer? _frameTimer;
  DateTime _frameNow = DateTime.now();

  @override
  void initState() {
    super.initState();
    _syncFrameTimer();
  }

  @override
  void didUpdateWidget(covariant FlutterMapSurface oldWidget) {
    super.didUpdateWidget(oldWidget);
    _syncFrameTimer();
  }

  @override
  void dispose() {
    _frameTimer?.cancel();
    super.dispose();
  }

  void _syncFrameTimer() {
    final needsFrames = widget.vehicles.any((vehicle) => vehicle.isMoving);
    if (!needsFrames) {
      _frameTimer?.cancel();
      _frameTimer = null;
      _frameNow = DateTime.now();
      return;
    }
    _frameTimer ??= Timer.periodic(const Duration(milliseconds: 100), (_) {
      if (!mounted) {
        return;
      }
      setState(() {
        _frameNow = DateTime.now();
      });
      if (!widget.vehicles.any(
        (vehicle) => vehicle.isMoving && vehicle.progressAt(_frameNow) < 1,
      )) {
        _frameTimer?.cancel();
        _frameTimer = null;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final adapter = widget.mapController as FlutterMapControllerAdapter;

    return ClipRRect(
      borderRadius: BorderRadius.circular(22),
      child: FlutterMap(
        mapController: adapter.mapController,
        options: MapOptions(
          initialCenter: ll.LatLng(
            widget.mapController.camera.centerLat,
            widget.mapController.camera.centerLng,
          ),
          initialZoom: widget.mapController.camera.zoom,
          onMapReady: adapter.onMapReady,
          onPositionChanged: (position, hasGesture) {
            widget.mapController.setCamera(
              AppMapCamera(
                centerLat: position.center.latitude,
                centerLng: position.center.longitude,
                zoom: position.zoom,
              ),
            );
          },
          onMapEvent: (event) {
            if (event is MapEventMoveEnd) {
              widget.onCameraIdle?.call();
            }
          },
        ),
        children: [
          TileLayer(
            urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
            userAgentPackageName: 'ua.gov.dozor.city',
          ),
          PolylineLayer(polylines: _buildPolylines()),
          MarkerLayer(markers: _buildMarkers()),
        ],
      ),
    );
  }

  List<Marker> _buildMarkers() {
    final markers = widget.vehicles.map((animatedVehicle) {
      final vehicle = animatedVehicle.vehicleAt(_frameNow);
      return Marker(
        point: ll.LatLng(vehicle.lat, vehicle.lng),
        width: 30,
        height: 30,
        child: GestureDetector(
          behavior: HitTestBehavior.translucent,
          onTap: widget.onVehicleTap == null
              ? null
              : () => widget.onVehicleTap!(vehicle),
          child: VehicleMarkerWidget(
            vehicle: vehicle,
            selectedRoutesCount: widget.selectedRoutesCount,
            routeColorValue: widget.routeColorsById[vehicle.routeId],
          ),
        ),
      );
    }).toList();

    final start = widget.previewStart;
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

    final end = widget.previewEnd;
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
    final polylines = widget.routePolylines
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
    if (widget.previewGeometry.isNotEmpty) {
      return [
        ...polylines,
        Polyline(
          points: widget.previewGeometry
              .map((point) => ll.LatLng(point.lat, point.lng))
              .toList(),
          color: const Color(0xFFFCB813),
          strokeWidth: 6,
        ),
      ];
    }

    final start = widget.previewStart;
    final end = widget.previewEnd;
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
