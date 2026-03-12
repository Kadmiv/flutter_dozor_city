import 'package:flutter/material.dart';
import 'package:flutter_dozor_city/core/domain/entities/app_lat_lng.dart';
import 'package:flutter_dozor_city/core/domain/entities/selected_point.dart';
import 'package:flutter_dozor_city/core/domain/entities/transport_route.dart';
import 'package:flutter_dozor_city/core/map/app_map_provider.dart';
import 'package:flutter_dozor_city/core/map/google_map_surface.dart';
import 'package:flutter_dozor_city/core/map/flutter_map_surface.dart';
import 'package:flutter_dozor_city/core/map/map_controller.dart';
import 'package:flutter_dozor_city/features/live_tracking/domain/entities/vehicle_entity.dart';

class AppMapSurface extends StatelessWidget {
  const AppMapSurface({
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
    switch (AppMapConfiguration.currentProvider) {
      case AppMapProvider.google:
        return GoogleMapSurface(
          mapController: mapController,
          vehicles: vehicles,
          routePolylines: routePolylines,
          previewGeometry: previewGeometry,
          previewStart: previewStart,
          previewEnd: previewEnd,
          onCameraIdle: onCameraIdle != null ? (_) => onCameraIdle!() : null,
        );
      case AppMapProvider.openStreetMap:
        return FlutterMapSurface(
          mapController: mapController,
          vehicles: vehicles,
          routePolylines: routePolylines,
          previewGeometry: previewGeometry,
          previewStart: previewStart,
          previewEnd: previewEnd,
          onCameraIdle: onCameraIdle,
        );
    }
  }
}
