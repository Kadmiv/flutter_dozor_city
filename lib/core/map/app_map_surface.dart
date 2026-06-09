import 'package:flutter/material.dart';
import 'package:flutter_dozor_city/core/domain/entities/app_lat_lng.dart';
import 'package:flutter_dozor_city/core/domain/entities/selected_point.dart';
import 'package:flutter_dozor_city/core/domain/entities/route_zone.dart';
import 'package:flutter_dozor_city/core/domain/entities/transport_route.dart';
import 'package:flutter_dozor_city/core/map/app_map_provider.dart';
import 'package:flutter_dozor_city/core/map/google_map_surface.dart';
import 'package:flutter_dozor_city/core/map/flutter_map_surface.dart';
import 'package:flutter_dozor_city/core/map/map_controller.dart';
import 'package:flutter_dozor_city/core/domain/entities/vehicle.dart';
import 'package:flutter_dozor_city/features/live_tracking/domain/entities/animated_vehicle.dart';

class AppMapSurface extends StatelessWidget {
  const AppMapSurface({
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
  Widget build(BuildContext context) {
    switch (AppMapConfiguration.currentProvider) {
      case AppMapProvider.google:
        return GoogleMapSurface(
          mapController: mapController,
          vehicles: vehicles,
          selectedRoutesCount: selectedRoutesCount,
          routeColorsById: routeColorsById,
          showMarkers: showMarkers,
          cityStops: cityStops,
          onVehicleTap: onVehicleTap,
          onCityStopTap: onCityStopTap,
          routePolylines: routePolylines,
          previewGeometry: previewGeometry,
          previewStart: previewStart,
          previewEnd: previewEnd,
          selectedRouteStatus: selectedRouteStatus,
          onMapTap: onMapTap,
          onPreviewStartChanged: onPreviewStartChanged,
          onPreviewStartDragEnded: onPreviewStartDragEnded,
          onPreviewEndChanged: onPreviewEndChanged,
          onPreviewEndDragEnded: onPreviewEndDragEnded,
          onCameraIdle: onCameraIdle != null ? (_) => onCameraIdle!() : null,
        );
      case AppMapProvider.openStreetMap:
        return FlutterMapSurface(
          mapController: mapController,
          vehicles: vehicles,
          selectedRoutesCount: selectedRoutesCount,
          routeColorsById: routeColorsById,
          showMarkers: showMarkers,
          cityStops: cityStops,
          onVehicleTap: onVehicleTap,
          onCityStopTap: onCityStopTap,
          routePolylines: routePolylines,
          previewGeometry: previewGeometry,
          previewStart: previewStart,
          previewEnd: previewEnd,
          selectedRouteStatus: selectedRouteStatus,
          onMapTap: onMapTap,
          onPreviewStartChanged: onPreviewStartChanged,
          onPreviewStartDragEnded: onPreviewStartDragEnded,
          onPreviewEndChanged: onPreviewEndChanged,
          onPreviewEndDragEnded: onPreviewEndDragEnded,
          onCameraIdle: onCameraIdle,
        );
    }
  }
}
