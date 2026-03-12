import 'package:flutter/material.dart';
import 'package:flutter_dozor_city/features/main_map/presentation/widgets/map_overlays/arrival_info_panel.dart';
import 'package:flutter_dozor_city/features/main_map/presentation/widgets/map_overlays/routes_overlays_panel.dart';
import 'package:flutter_dozor_city/features/main_map/presentation/widgets/map_overlays/transport_types_bar.dart';

class MapOverlaysPanel extends StatelessWidget {
  const MapOverlaysPanel({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: const [
        TransportTypesBar(),
        SizedBox(height: 12),
        RoutesOverlaysPanel(),
        SizedBox(height: 12),
        ArrivalInfoPanel(),
      ],
    );
  }
}
