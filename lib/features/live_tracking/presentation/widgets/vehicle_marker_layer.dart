import 'package:flutter/material.dart';
import 'package:flutter_dozor_city/core/map/map_controller.dart';
import 'package:flutter_dozor_city/core/domain/entities/vehicle.dart';
import 'package:flutter_dozor_city/features/live_tracking/presentation/widgets/vehicle_marker_widget.dart';

class VehicleMarkerLayer extends StatefulWidget {
  const VehicleMarkerLayer({
    super.key,
    required this.mapController,
    required this.vehicles,
    required this.selectedRoutesCount,
    this.onVehicleTap,
  });

  final MapController mapController;
  final List<Vehicle> vehicles;
  final int selectedRoutesCount;
  final ValueChanged<Vehicle>? onVehicleTap;

  @override
  State<VehicleMarkerLayer> createState() => _VehicleMarkerLayerState();
}

class _VehicleMarkerLayerState extends State<VehicleMarkerLayer> {
  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final height = constraints.maxHeight;
        final projectedVehicles = widget.vehicles
            .map(
              (vehicle) => _ProjectedVehicle(
                vehicle: vehicle,
                left: _projectLeft(vehicle.lng, width),
                top: _projectTop(vehicle.lat, height),
              ),
            )
            .toList(growable: false);

        return Stack(
          children: projectedVehicles
              .map(
                (item) => AnimatedPositioned(
                  key: ValueKey(item.vehicle.id),
                  duration: const Duration(seconds: 9),
                  curve: Curves.linear,
                  left: item.left,
                  top: item.top,
                  child: GestureDetector(
                    behavior: HitTestBehavior.translucent,
                    onTap: widget.onVehicleTap == null
                        ? null
                        : () => widget.onVehicleTap!(item.vehicle),
                    child: Tooltip(
                      message:
                          '${item.vehicle.govNumber} • ${item.vehicle.speed} км/год',
                      child: VehicleMarkerWidget(
                        vehicle: item.vehicle,
                        selectedRoutesCount: widget.selectedRoutesCount,
                      ),
                    ),
                  ),
                ),
              )
              .toList(growable: false),
        );
      },
    );
  }

  double _projectLeft(double lng, double width) {
    final left = ((lng + 180) / 360) * width;
    return left.clamp(8, width - 56);
  }

  double _projectTop(double lat, double height) {
    final top = (1 - ((lat + 90) / 180)) * height;
    return top.clamp(8, height - 40);
  }
}

class _ProjectedVehicle {
  const _ProjectedVehicle({
    required this.vehicle,
    required this.left,
    required this.top,
  });

  final Vehicle vehicle;
  final double left;
  final double top;
}
