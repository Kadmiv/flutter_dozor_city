import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_dozor_city/core/domain/entities/app_lat_lng.dart';
import 'package:flutter_dozor_city/core/domain/entities/selected_point.dart';
import 'package:flutter_dozor_city/core/domain/entities/route_zone.dart';
import 'package:flutter_dozor_city/core/domain/entities/transport_route.dart';
import 'package:flutter_dozor_city/core/map/app_map_camera.dart';
import 'package:flutter_dozor_city/core/map/flutter_map_controller_adapter.dart';
import 'package:flutter_dozor_city/core/map/map_controller.dart';
import 'package:flutter_dozor_city/core/map/map_zoom_thresholds.dart';
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
    required this.showMarkers,
    this.cityStops = const [],
    this.onVehicleTap,
    this.onCityStopTap,
    this.routePolylines = const [],
    this.previewGeometry = const [],
    this.previewStart,
    this.previewEnd,
    this.selectedRouteStatus,
    this.onMapTap,
    this.onPreviewStartChanged,
    this.onPreviewStartDragEnded,
    this.onPreviewEndChanged,
    this.onPreviewEndDragEnded,
    this.onCameraIdle,
  });

  final MapController mapController;
  final List<AnimatedVehicle> vehicles;
  final int selectedRoutesCount;
  final Map<String, int> routeColorsById;
  final bool showMarkers;
  final List<RouteZone> cityStops;
  final ValueChanged<Vehicle>? onVehicleTap;
  final Future<void> Function(RouteZone)? onCityStopTap;
  final List<TransportRoute> routePolylines;
  final List<AppLatLng> previewGeometry;
  final SelectedPoint? previewStart;
  final SelectedPoint? previewEnd;
  final int? selectedRouteStatus;
  final ValueChanged<AppLatLng>? onMapTap;
  final ValueChanged<AppLatLng>? onPreviewStartChanged;
  final ValueChanged<AppLatLng>? onPreviewStartDragEnded;
  final ValueChanged<AppLatLng>? onPreviewEndChanged;
  final ValueChanged<AppLatLng>? onPreviewEndDragEnded;
  final VoidCallback? onCameraIdle;

  @override
  State<FlutterMapSurface> createState() => _FlutterMapSurfaceState();
}

class _FlutterMapSurfaceState extends State<FlutterMapSurface> {
  final GlobalKey _mapKey = GlobalKey();
  Timer? _frameTimer;
  DateTime _frameNow = DateTime.now();
  Offset? _lastDragPosition;

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
      key: _mapKey,
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
            setState(() {});
          },
          onMapEvent: (event) {
            if (event is MapEventMoveEnd) {
              widget.onCameraIdle?.call();
            }
          },
          onTap: widget.onMapTap == null
              ? null
              : (tapPosition, point) {
                  widget.onMapTap!(
                    AppLatLng(lat: point.latitude, lng: point.longitude),
                  );
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
    final markers = <Marker>[];
    final showCityStops =
        widget.showMarkers &&
        widget.mapController.camera.zoom >= kCityStopsZoomThreshold;
    if (showCityStops) {
      markers.addAll(
        widget.cityStops
            .where((stop) => stop.position != null)
            .map(
              (stop) => Marker(
                point: ll.LatLng(stop.position!.lat, stop.position!.lng),
                width: 24,
                height: 24,
                child: GestureDetector(
                  behavior: HitTestBehavior.translucent,
                  onTap: widget.onCityStopTap == null
                      ? null
                      : () {
                          unawaited(widget.onCityStopTap!(stop));
                        },
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: const Color(0xFF0F5B8D),
                      border: Border.all(color: Colors.white, width: 2),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: const Center(
                      child: Icon(
                        Icons.directions_bus_rounded,
                        size: 14,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ),
            ),
      );
    }
    if (widget.showMarkers) {
      markers.addAll(
        widget.vehicles.map((animatedVehicle) {
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
        }),
      );
    }

    final start = widget.previewStart;
    if (start != null) {
      markers.add(
        Marker(
          point: ll.LatLng(start.lat, start.lng),
          width: 40,
          height: 40,
          child: GestureDetector(
            behavior: HitTestBehavior.translucent,
            onPanUpdate: widget.onPreviewStartChanged == null
                ? null
                : (details) {
                    _lastDragPosition = details.globalPosition;
                    final point = _latLngFromGlobalPosition(
                      details.globalPosition,
                    );
                    if (point != null) {
                      widget.onPreviewStartChanged!(point);
                    }
                  },
            onPanEnd: widget.onPreviewStartDragEnded == null
                ? null
                : (details) {
                    final point = _lastDragPosition == null
                        ? null
                        : _latLngFromGlobalPosition(_lastDragPosition!);
                    if (point != null) {
                      widget.onPreviewStartDragEnded!(point);
                    }
                    _lastDragPosition = null;
                  },
            onPanStart: (details) {
              _lastDragPosition = details.globalPosition;
            },
            onPanDown: (details) {
              _lastDragPosition = details.globalPosition;
            },
            child: const Icon(Icons.location_on, color: Colors.green, size: 40),
          ),
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
          child: GestureDetector(
            behavior: HitTestBehavior.translucent,
            onPanUpdate: widget.onPreviewEndChanged == null
                ? null
                : (details) {
                    _lastDragPosition = details.globalPosition;
                    final point = _latLngFromGlobalPosition(
                      details.globalPosition,
                    );
                    if (point != null) {
                      widget.onPreviewEndChanged!(point);
                    }
                  },
            onPanEnd: widget.onPreviewEndDragEnded == null
                ? null
                : (details) {
                    final point = _lastDragPosition == null
                        ? null
                        : _latLngFromGlobalPosition(_lastDragPosition!);
                    if (point != null) {
                      widget.onPreviewEndDragEnded!(point);
                    }
                    _lastDragPosition = null;
                  },
            onPanStart: (details) {
              _lastDragPosition = details.globalPosition;
            },
            onPanDown: (details) {
              _lastDragPosition = details.globalPosition;
            },
            child: const Icon(Icons.location_on, color: Colors.red, size: 40),
          ),
        ),
      );
    }

    return markers;
  }

  AppLatLng? _latLngFromGlobalPosition(Offset globalPosition) {
    final context = _mapKey.currentContext;
    if (context == null) {
      return null;
    }
    final renderObject = context.findRenderObject();
    if (renderObject is! RenderBox) {
      return null;
    }
    final localPosition = renderObject.globalToLocal(globalPosition);
    final camera = (widget.mapController as FlutterMapControllerAdapter)
        .mapController
        .camera;
    final latLng = camera.offsetToCrs(localPosition);
    return AppLatLng(lat: latLng.latitude, lng: latLng.longitude);
  }

  List<Polyline> _buildPolylines() {
    final polylines = widget.routePolylines
        .expand(
          (route) => route
              .displayPolylineSegments(widget.selectedRouteStatus)
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
