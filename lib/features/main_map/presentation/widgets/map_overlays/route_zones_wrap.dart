import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_dozor_city/core/domain/entities/route_zone.dart';
import 'package:flutter_dozor_city/features/main_map/presentation/bloc/main_map_cubit.dart';
import 'package:flutter_dozor_city/features/main_map/presentation/bloc/map_overlays_cubit.dart';

class RouteZonesWrap extends StatelessWidget {
  const RouteZonesWrap({super.key, required this.zones});

  final List<RouteZone> zones;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: zones
          .map(
            (zone) => GestureDetector(
              onTap: () {
                final cityId = context.read<MainMapCubit>().state.city?.id;
                if (cityId == null) {
                  return;
                }
                context.read<MainMapCubit>().setActiveMapActionLabel(
                      'Зупинка ${zone.name}',
                    );
                context.read<MapOverlaysCubit>().loadArrival(
                      cityId: cityId,
                      zoneId: zone.id,
                    );
              },
              child: Chip(
                label: Text(zone.name),
                backgroundColor: Colors.white.withValues(alpha: 0.15),
                labelStyle: const TextStyle(color: Colors.white),
              ),
            ),
          )
          .toList(growable: false),
    );
  }
}
