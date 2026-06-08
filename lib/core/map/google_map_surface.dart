import 'dart:async';

import 'package:flutter_dozor_city/core/domain/entities/app_lat_lng.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dozor_city/core/domain/entities/selected_point.dart';
import 'package:flutter_dozor_city/core/domain/entities/route_zone.dart';
import 'package:flutter_dozor_city/core/domain/entities/transport_route.dart';
import 'package:flutter_dozor_city/core/map/app_map_camera.dart';
import 'package:flutter_dozor_city/core/map/map_controller.dart';
import 'package:flutter_dozor_city/core/map/google_map_controller_adapter.dart';
import 'package:flutter_dozor_city/core/map/map_zoom_thresholds.dart';
import 'package:flutter_dozor_city/core/domain/entities/vehicle.dart';
import 'package:flutter_dozor_city/features/live_tracking/domain/entities/animated_vehicle.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart' as gmaps;

class GoogleMapSurface extends StatefulWidget {
  const GoogleMapSurface({
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
  final ValueChanged<gmaps.CameraPosition>? onCameraIdle;

  @override
  State<GoogleMapSurface> createState() => _GoogleMapSurfaceState();
}

class _GoogleMapSurfaceState extends State<GoogleMapSurface> {
  Timer? _frameTimer;
  DateTime _frameNow = DateTime.now();

  @override
  void initState() {
    super.initState();
    _syncFrameTimer();
  }

  @override
  void didUpdateWidget(covariant GoogleMapSurface oldWidget) {
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
    return ClipRRect(
      borderRadius: BorderRadius.circular(22),
      child: gmaps.GoogleMap(
        initialCameraPosition: gmaps.CameraPosition(
          target: gmaps.LatLng(
            widget.mapController.camera.centerLat,
            widget.mapController.camera.centerLng,
          ),
          zoom: widget.mapController.camera.zoom,
        ),
        myLocationButtonEnabled: false,
        zoomControlsEnabled: false,
        mapToolbarEnabled: false,
        onMapCreated: (controller) =>
            (widget.mapController as GoogleMapControllerAdapter).bind(
              controller,
            ),
        onCameraIdle: () => widget.onCameraIdle?.call(
          gmaps.CameraPosition(
            target: gmaps.LatLng(
              widget.mapController.camera.centerLat,
              widget.mapController.camera.centerLng,
            ),
            zoom: widget.mapController.camera.zoom,
          ),
        ),
        onCameraMove: (position) {
          widget.mapController.cacheCamera(
            AppMapCamera(
              centerLat: position.target.latitude,
              centerLng: position.target.longitude,
              zoom: position.zoom,
            ),
          );
          setState(() {});
        },
        onTap: widget.onMapTap == null
            ? null
            : (latLng) => widget.onMapTap!(
                AppLatLng(lat: latLng.latitude, lng: latLng.longitude),
              ),
        markers: _buildMarkers(),
        polylines: _buildPolylines(),
      ),
    );
  }

  Set<gmaps.Marker> _buildMarkers() {
    final markers = <gmaps.Marker>{};
    final showCityStops =
        widget.showMarkers &&
        widget.mapController.camera.zoom >= kCityStopsZoomThreshold;
    if (showCityStops) {
      markers.addAll(
        widget.cityStops
            .where((stop) => stop.position != null)
            .map(
              (stop) => gmaps.Marker(
                markerId: gmaps.MarkerId('stop-${stop.id}'),
                position: gmaps.LatLng(stop.position!.lat, stop.position!.lng),
                anchor: const Offset(0.5, 1.0),
                zIndexInt: 1,
                onTap: widget.onCityStopTap == null
                    ? null
                    : () {
                        unawaited(widget.onCityStopTap!(stop));
                      },
                icon: gmaps.BitmapDescriptor.defaultMarkerWithHue(
                  gmaps.BitmapDescriptor.hueAzure,
                ),
                infoWindow: gmaps.InfoWindow(title: stop.name),
              ),
            ),
      );
    }
    if (widget.showMarkers) {
      markers.addAll(
        widget.vehicles.map((animatedVehicle) {
          final vehicle = animatedVehicle.vehicleAt(_frameNow);
          return gmaps.Marker(
            markerId: gmaps.MarkerId(vehicle.id),
            position: gmaps.LatLng(vehicle.lat, vehicle.lng),
            rotation: vehicle.azimuth.toDouble(),
            anchor: const Offset(0.5, 0.5),
            zIndexInt: 2,
            onTap: widget.onVehicleTap == null
                ? null
                : () => widget.onVehicleTap!(vehicle),
            icon: gmaps.BitmapDescriptor.defaultMarkerWithHue(
              _markerHueForColor(
                Color(widget.routeColorsById[vehicle.routeId] ?? 0xFFC8102E),
              ),
            ),
            infoWindow: gmaps.InfoWindow(
              title: 'Маршрут ${vehicle.routeShortName} • ${vehicle.govNumber}',
              snippet: '${vehicle.routeTitle} • ${vehicle.speed} км/год',
            ),
          );
        }),
      );
    }
    final start = widget.previewStart;
    if (start != null) {
      markers.add(
        gmaps.Marker(
          markerId: const gmaps.MarkerId('preview-start'),
          position: gmaps.LatLng(start.lat, start.lng),
          zIndexInt: 3,
          icon: gmaps.BitmapDescriptor.defaultMarkerWithHue(
            gmaps.BitmapDescriptor.hueGreen,
          ),
          infoWindow: gmaps.InfoWindow(title: 'Старт', snippet: start.label),
        ),
      );
    }
    final end = widget.previewEnd;
    if (end != null) {
      markers.add(
        gmaps.Marker(
          markerId: const gmaps.MarkerId('preview-end'),
          position: gmaps.LatLng(end.lat, end.lng),
          zIndexInt: 3,
          icon: gmaps.BitmapDescriptor.defaultMarkerWithHue(
            gmaps.BitmapDescriptor.hueRed,
          ),
          infoWindow: gmaps.InfoWindow(title: 'Фініш', snippet: end.label),
        ),
      );
    }
    return markers;
  }

  double _markerHueForColor(Color color) {
    final hsv = HSVColor.fromColor(color);
    return hsv.hue;
  }

  Set<gmaps.Polyline> _buildPolylines() {
    final polylines = widget.routePolylines
        .expand(
          (route) => route
              .displayPolylineSegments(widget.selectedRouteStatus)
              .indexed
              .where((entry) => entry.$2.length > 1)
              .map(
                (entry) => gmaps.Polyline(
                  polylineId: gmaps.PolylineId('route-${route.id}-${entry.$1}'),
                  points: entry.$2
                      .map((point) => gmaps.LatLng(point.lat, point.lng))
                      .toList(growable: false),
                  color: Color(route.lineColorValue),
                  width: 5,
                ),
              ),
        )
        .toSet();
    final start = widget.previewStart;
    final end = widget.previewEnd;
    if (widget.previewGeometry.isNotEmpty) {
      polylines.add(
        gmaps.Polyline(
          polylineId: const gmaps.PolylineId('preview-line'),
          points: widget.previewGeometry
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
