import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_dozor_city/core/domain/entities/route_preview_segment.dart';
import 'package:flutter_dozor_city/features/route_preview/presentation/bloc/route_preview_cubit.dart';
import 'package:flutter_dozor_city/features/route_results/presentation/widgets/legacy_route_card.dart';
import 'package:flutter_dozor_city/features/stored_routes/presentation/bloc/stored_routes_cubit.dart';

class StoredRoutesPage extends StatelessWidget {
  const StoredRoutesPage({super.key, required this.cubit});

  final StoredRoutesCubit cubit;

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: cubit,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 12, 12, 16),
        child: BlocBuilder<StoredRoutesCubit, StoredRoutesState>(
          builder: (context, state) {
            if (state.isLoading) {
              return const Center(child: CircularProgressIndicator());
            }
            if (state.routes.isEmpty) {
              return const Center(
                child: Text('Збережених маршрутів поки немає'),
              );
            }
            return ListView.separated(
              itemCount: state.routes.length,
              separatorBuilder: (_, index) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                final route = state.routes[index];
                return LegacyRouteCard(
                  route: route,
                  leadingBadges: [
                    LegacyRouteBadgeData(
                      icon: route.previewSegments.any(
                        (segment) =>
                            segment.type == RoutePreviewSegmentType.transfer,
                      )
                          ? Icons.swap_horiz
                          : Icons.directions_bus,
                      label: route.title,
                    ),
                    LegacyRouteBadgeData(
                      icon: Icons.bookmark,
                      label: '${route.startName} -> ${route.endName}',
                    ),
                  ],
                  trailing: IconButton(
                    onPressed: () =>
                        context.read<StoredRoutesCubit>().deleteRoute(route.id),
                    icon: const Icon(Icons.delete_outline),
                  ),
                  onPrimaryAction: () =>
                      context.read<RoutePreviewCubit>().show(route),
                  primaryActionLabel: 'Показати',
                );
              },
            );
          },
        ),
      ),
    );
  }
}
