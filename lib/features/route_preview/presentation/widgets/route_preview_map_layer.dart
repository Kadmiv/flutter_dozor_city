import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_dozor_city/core/domain/entities/transport_route.dart';
import 'package:flutter_dozor_city/core/map/app_map_surface.dart';
import 'package:flutter_dozor_city/core/map/map_controller.dart';
import 'package:flutter_dozor_city/features/live_tracking/domain/entities/vehicle_entity.dart';
import 'package:flutter_dozor_city/features/main_map/presentation/bloc/map_overlays_cubit.dart';
import 'package:flutter_dozor_city/features/route_preview/presentation/bloc/route_preview_cubit.dart';

class RoutePreviewMapLayer extends StatelessWidget {
  const RoutePreviewMapLayer({
    super.key,
    required this.mapController,
    required this.vehicles,
    required this.onCameraIdle,
    this.routePolylines = const [],
  });

  final MapController mapController;
  final List<VehicleEntity> vehicles;
  final VoidCallback onCameraIdle;
  final List<TransportRoute> routePolylines;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<MapOverlaysCubit, MapOverlaysState>(
      builder: (context, overlaysState) {
        return BlocBuilder<RoutePreviewCubit, RoutePreviewState>(
          builder: (context, previewState) {
            return AppMapSurface(
              mapController: mapController,
              vehicles: vehicles,
              routePolylines: routePolylines.isEmpty
                  ? overlaysState.selectedRoutes
                  : routePolylines,
              previewGeometry: previewState.route?.previewGeometry ?? const [],
              previewStart: previewState.start,
              previewEnd: previewState.end,
              onCameraIdle: onCameraIdle,
            );
          },
        );
      },
    );
  }
}
