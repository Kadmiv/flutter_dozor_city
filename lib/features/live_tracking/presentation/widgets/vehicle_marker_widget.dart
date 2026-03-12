import 'package:flutter/material.dart';
import 'package:flutter_dozor_city/features/live_tracking/domain/entities/vehicle_entity.dart';

class VehicleMarkerWidget extends StatelessWidget {
  const VehicleMarkerWidget({
    super.key,
    required this.vehicle,
  });

  final VehicleEntity vehicle;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        AnimatedRotation(
          duration: const Duration(milliseconds: 900),
          turns: vehicle.azimuth / 360,
          curve: Curves.easeOut,
          child: Container(
            width: 22,
            height: 22,
            decoration: BoxDecoration(
              color: const Color(0xFFF97316),
              borderRadius: BorderRadius.circular(11),
              border: Border.all(color: Colors.white, width: 2),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x33000000),
                  blurRadius: 8,
                  offset: Offset(0, 4),
                ),
              ],
            ),
            child: const Icon(
              Icons.navigation,
              size: 12,
              color: Colors.white,
            ),
          ),
        ),
        const SizedBox(height: 4),
        DecoratedBox(
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.45),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            child: Text(
              vehicle.govNumber,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 10,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
