import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_dozor_city/core/domain/entities/app_lat_lng.dart';
import 'package:flutter_dozor_city/core/domain/entities/selected_point.dart';
import 'package:flutter_dozor_city/core/domain/entities/route_zone.dart';
import 'package:flutter_dozor_city/core/domain/entities/transport_route.dart';
import 'package:flutter_dozor_city/core/domain/entities/route_status_filter.dart';
import 'package:flutter_dozor_city/core/map/app_map_surface.dart';
import 'package:flutter_dozor_city/core/map/map_controller.dart';
import 'package:flutter_dozor_city/core/domain/entities/vehicle.dart';
import 'package:flutter_dozor_city/features/live_tracking/domain/entities/animated_vehicle.dart';
import 'package:flutter_dozor_city/features/main_map/presentation/bloc/map_routes_cubit.dart';
import 'package:flutter_dozor_city/features/main_map/presentation/bloc/map_arrivals_cubit.dart';
import 'package:flutter_dozor_city/features/route_preview/presentation/bloc/route_preview_cubit.dart';

class RoutePreviewMapLayer extends StatelessWidget {
  const RoutePreviewMapLayer({
    super.key,
    required this.mapController,
    required this.vehicles,
    required this.selectedRoutesCount,
    required this.routeColorsById,
    required this.showMarkers,
    this.cityStops = const [],
    this.onVehicleTap,
    this.onCityStopTap,
    required this.onCameraIdle,
    this.onMapTap,
    this.onPreviewStartChanged,
    this.onPreviewStartDragEnded,
    this.onPreviewEndChanged,
    this.onPreviewEndDragEnded,
    this.previewStart,
    this.previewEnd,
    this.routePolylines = const [],
  });

  final MapController mapController;
  final List<AnimatedVehicle> vehicles;
  final int selectedRoutesCount;
  final Map<String, int> routeColorsById;
  final bool showMarkers;
  final List<RouteZone> cityStops;
  final ValueChanged<Vehicle>? onVehicleTap;
  final Future<void> Function(RouteZone)? onCityStopTap;
  final VoidCallback onCameraIdle;
  final ValueChanged<AppLatLng>? onMapTap;
  final ValueChanged<AppLatLng>? onPreviewStartChanged;
  final ValueChanged<AppLatLng>? onPreviewStartDragEnded;
  final ValueChanged<AppLatLng>? onPreviewEndChanged;
  final ValueChanged<AppLatLng>? onPreviewEndDragEnded;
  final SelectedPoint? previewStart;
  final SelectedPoint? previewEnd;
  final List<TransportRoute> routePolylines;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<MapRoutesBloc, MapRoutesState>(
      builder: (context, mapRoutesState) {
        return BlocBuilder<MapArrivalsBloc, MapArrivalsState>(
          builder: (context, _) {
            return BlocBuilder<RoutePreviewBloc, RoutePreviewState>(
              builder: (context, previewState) {
                final selectedRoutes = mapRoutesState.selectedRoutes;
                final routesToDraw = routePolylines.isEmpty
                    ? selectedRoutes
                    : routePolylines;

                return AppMapSurface(
                  mapController: mapController,
                  vehicles: vehicles,
                  selectedRoutesCount: selectedRoutesCount,
                  routeColorsById: routeColorsById,
                  showMarkers: showMarkers,
                  cityStops: cityStops,
                  onVehicleTap: onVehicleTap,
                  onCityStopTap: onCityStopTap,
                  routePolylines: routesToDraw,
                  previewGeometry:
                      previewState.route?.previewGeometry ?? const [],
                  previewStart: previewStart ?? previewState.start,
                  previewEnd: previewEnd ?? previewState.end,
                  selectedRouteStatus:
                      mapRoutesState.selectedStatus.statusValue,
                  onMapTap: onMapTap,
                  onPreviewStartChanged: onPreviewStartChanged,
                  onPreviewStartDragEnded: onPreviewStartDragEnded,
                  onPreviewEndChanged: onPreviewEndChanged,
                  onPreviewEndDragEnded: onPreviewEndDragEnded,
                  onCameraIdle: onCameraIdle,
                );
              },
            );
          },
        );
      },
    );
  }
}
