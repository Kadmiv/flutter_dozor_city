import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_dozor_city/features/main_map/presentation/bloc/main_map_cubit.dart';
import 'package:flutter_dozor_city/features/main_map/presentation/bloc/map_overlays_cubit.dart';
import 'package:flutter_dozor_city/features/main_map/presentation/widgets/map_overlays/route_zones_wrap.dart';

class RoutesOverlaysPanel extends StatelessWidget {
  const RoutesOverlaysPanel({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<MapOverlaysCubit, MapOverlaysState>(
      builder: (context, state) {
        if (state.isLoading && state.availableRoutes.isEmpty) {
          return const LinearProgressIndicator();
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              state.selectedRoutes.isEmpty
                  ? 'Маршрути ще не вибрані'
                  : 'Вибрані маршрути: ${state.selectedRoutes.map((route) => route.shortName).join(', ')}',
              style: const TextStyle(
                color: Color(0xFF17324D),
                fontWeight: FontWeight.w600,
              ),
            ),
            if (state.selectedRoutes.isNotEmpty) ...[
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: state.selectedRoutes
                    .map(
                      (route) => InputChip(
                        label: Text(route.shortName),
                        selected: state.activeRouteId == route.id,
                        onPressed: () {
                          final cityId = context.read<MainMapCubit>().state.city?.id;
                          if (cityId == null) {
                            return;
                          }
                          context.read<MainMapCubit>()
                            ..setRouteMode(MainMapMode.routes)
                            ..setActiveMapActionLabel(
                              'Маршрут ${route.shortName}',
                            );
                          context.read<MapOverlaysCubit>().selectRoute(
                                cityId: cityId,
                                route: route,
                              );
                        },
                        onDeleted: () async {
                          final overlaysCubit = context.read<MapOverlaysCubit>();
                          final mainMapCubit = context.read<MainMapCubit>();
                          await overlaysCubit.removeRoute(route.id);
                          final remaining = overlaysCubit.state.selectedRoutes;
                          mainMapCubit.setActiveMapActionLabel(
                                remaining.isEmpty
                                    ? 'Маршрути очищено'
                                    : 'Маршрут ${remaining.last.shortName}',
                              );
                        },
                      ),
                    )
                    .toList(growable: false),
              ),
            ],
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: state.availableRoutes
                  .map(
                    (route) => FilterChip(
                      label: Text(route.shortName),
                      selected: state.selectedRoutes.contains(route),
                      onSelected: (_) {
                        final cityId = context.read<MainMapCubit>().state.city?.id;
                        if (cityId == null) {
                          return;
                        }
                        context.read<MainMapCubit>()
                          ..setRouteMode(MainMapMode.routes)
                          ..setActiveMapActionLabel(
                            'Маршрут ${route.shortName}',
                          );
                        context.read<MapOverlaysCubit>().selectRoute(
                              cityId: cityId,
                              route: route,
                            );
                      },
                    ),
                  )
                  .toList(growable: false),
            ),
            if (state.routeZones.isNotEmpty) ...[
              const SizedBox(height: 12),
              RouteZonesWrap(zones: state.routeZones),
            ],
          ],
        );
      },
    );
  }
}
