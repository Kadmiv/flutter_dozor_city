import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_dozor_city/core/domain/entities/route_preview_segment.dart';
import 'package:flutter_dozor_city/features/route_preview/presentation/bloc/route_preview_cubit.dart';
import 'package:flutter_dozor_city/features/route_results/presentation/bloc/route_results_cubit.dart';
import 'package:flutter_dozor_city/features/route_results/presentation/widgets/legacy_route_card.dart';

class RouteResultsPage extends StatelessWidget {
  const RouteResultsPage({super.key, required this.cubit});

  final RouteResultsCubit cubit;

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: cubit,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 12, 12, 16),
        child: BlocBuilder<RouteResultsCubit, RouteResultsState>(
          builder: (context, state) {
            if (state.isLoading) {
              return const Center(child: CircularProgressIndicator());
            }
            if (state.results.isEmpty) {
              return const Center(
                child: Text('Маршрути не знайдені або пошук ще не запускався'),
              );
            }
            return ListView.separated(
              itemCount: state.results.length,
              separatorBuilder: (_, index) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                final result = state.results[index];
                return LegacyRouteCard(
                  route: result,
                  leadingBadges: [
                    LegacyRouteBadgeData(
                      icon: result.previewSegments.any(
                        (segment) =>
                            segment.type == RoutePreviewSegmentType.transfer,
                      )
                          ? Icons.swap_horiz
                          : Icons.directions_bus,
                      label: result.title,
                    ),
                    LegacyRouteBadgeData(
                      icon: Icons.place_outlined,
                      label: '${result.startName} -> ${result.endName}',
                    ),
                  ],
                  trailing: IconButton(
                    onPressed: () =>
                        context.read<RouteResultsCubit>().toggleStored(result),
                    icon: Icon(
                      result.isStored ? Icons.bookmark : Icons.bookmark_border,
                    ),
                  ),
                  onPrimaryAction: () {
                    context.read<RoutePreviewCubit>().show(
                          result,
                          searchParams: state.params,
                        );
                  },
                  primaryActionLabel: 'Показати',
                  onSecondaryAction: () =>
                      context.read<RouteResultsCubit>().toggleStored(result),
                  secondaryActionLabel:
                      result.isStored ? 'Видалити' : 'Зберегти',
                  secondaryActionIcon: result.isStored
                      ? Icons.bookmark_remove
                      : Icons.bookmark_add,
                );
              },
            );
          },
        ),
      ),
    );
  }
}
