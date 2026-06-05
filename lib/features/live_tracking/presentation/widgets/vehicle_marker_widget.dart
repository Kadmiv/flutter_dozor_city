import 'package:flutter/material.dart';
import 'package:flutter_dozor_city/core/domain/entities/vehicle.dart';

class VehicleMarkerWidget extends StatelessWidget {
  const VehicleMarkerWidget({
    super.key,
    required this.vehicle,
    required this.selectedRoutesCount,
    this.routeColorValue,
  });

  final Vehicle vehicle;
  final int selectedRoutesCount;
  final int? routeColorValue;

  @override
  Widget build(BuildContext context) {
    final markerColor = Color(routeColorValue ?? 0xFFC8102E);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (selectedRoutesCount >= 2)
          Container(
            margin: const EdgeInsets.only(bottom: 3),
            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
            decoration: BoxDecoration(
              color: markerColor,
              borderRadius: BorderRadius.circular(999),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x22000000),
                  blurRadius: 6,
                  offset: Offset(0, 3),
                ),
              ],
            ),
            child: Text(
              vehicle.routeShortName,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 10,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        AnimatedRotation(
          duration: const Duration(milliseconds: 900),
          turns: vehicle.azimuth / 360,
          curve: Curves.easeOut,
          child: Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              color: markerColor,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 2),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x33000000),
                  blurRadius: 10,
                  offset: Offset(0, 4),
                ),
              ],
            ),
            child: const Icon(
              Icons.navigation,
              size: 15,
              color: Colors.white,
            ),
          ),
        ),
      ],
    );
  }
}
