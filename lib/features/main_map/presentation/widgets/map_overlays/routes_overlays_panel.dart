import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_dozor_city/features/main_map/presentation/bloc/main_map_cubit.dart';
import 'package:flutter_dozor_city/features/main_map/presentation/bloc/map_arrivals_cubit.dart';
import 'package:flutter_dozor_city/features/main_map/presentation/bloc/map_routes_cubit.dart';
import 'package:flutter_dozor_city/features/main_map/presentation/widgets/map_overlays/route_zones_wrap.dart';

class RoutesOverlaysPanel extends StatelessWidget {
  const RoutesOverlaysPanel({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<MapRoutesBloc, MapRoutesState>(
      builder: (context, routesState) {
        return BlocBuilder<MapArrivalsBloc, MapArrivalsState>(
          builder: (context, arrivalsState) {
            if (routesState.isLoading && routesState.availableRoutes.isEmpty) {
              return const LinearProgressIndicator();
            }
            final selectedRoutes = routesState.selectedRoutes;
            final routeZones = arrivalsState.routeZones;
            final activeRouteId = routesState.activeRouteId;
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  selectedRoutes.isEmpty
                      ? 'Маршрути ще не вибрані'
                      : 'Вибрані маршрути: ${selectedRoutes.map((route) => route.shortName).join(', ')}',
                  style: const TextStyle(
                    color: Color(0xFF17324D),
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (selectedRoutes.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: selectedRoutes
                        .map(
                          (route) => InputChip(
                            label: Text(route.shortName),
                            selected: activeRouteId == route.id,
                            onPressed: () {
                              final cityId =
                                  context.read<MainMapBloc>().state.city?.id;
                              if (cityId == null) {
                                return;
                              }
                              context.read<MainMapBloc>()
                                ..setRouteMode(MainMapMode.routes)
                                ..setActiveMapActionLabel(
                                  'Маршрут ${route.shortName}',
                                );
                              context.read<MapRoutesBloc>().selectRoute(
                                    cityId: cityId,
                                    route: route,
                                  );
                            },
                            onDeleted: () async {
                              final routesBloc = context.read<MapRoutesBloc>();
                              final mainMapBloc = context.read<MainMapBloc>();
                              await routesBloc.removeRoute(route.id);
                              final remaining = routesBloc.state.selectedRoutes;
                              mainMapBloc.setActiveMapActionLabel(
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
                  children: routesState.availableRoutes
                      .map(
                        (route) => FilterChip(
                          label: Text(route.shortName),
                          selected: selectedRoutes.contains(route),
                          onSelected: (_) {
                            final cityId =
                                context.read<MainMapBloc>().state.city?.id;
                            if (cityId == null) {
                              return;
                            }
                            context.read<MainMapBloc>()
                              ..setRouteMode(MainMapMode.routes)
                              ..setActiveMapActionLabel(
                                'Маршрут ${route.shortName}',
                              );
                            context.read<MapRoutesBloc>().selectRoute(
                                  cityId: cityId,
                                  route: route,
                                );
                          },
                        ),
                      )
                      .toList(growable: false),
                ),
                if (routeZones.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  RouteZonesWrap(zones: routeZones),
                ],
              ],
            );
          },
        );
      },
    );
  }
}
