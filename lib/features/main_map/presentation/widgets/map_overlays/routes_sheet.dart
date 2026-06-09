import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_dozor_city/core/domain/entities/transport_route.dart';
import 'package:flutter_dozor_city/features/main_map/presentation/widgets/route_planning_panel.dart';
import 'package:flutter_dozor_city/features/main_map/presentation/bloc/map_routes_cubit.dart';
import 'package:flutter_dozor_city/features/point_select/presentation/bloc/point_select_cubit.dart';

class RoutesSheet extends StatelessWidget {
  const RoutesSheet({
    super.key,
    required this.transportType,
    required this.onRouteTap,
    required this.createPointSelectBloc,
  });

  final int transportType;
  final ValueChanged<TransportRoute> onRouteTap;
  final PointSelectBloc Function() createPointSelectBloc;

  @override
  Widget build(BuildContext context) {
    return FractionallySizedBox(
      key: const Key('routes-sheet'),
      heightFactor: 0.86,
      child: DecoratedBox(
        decoration: const BoxDecoration(
          color: Color(0xFFF5F0E5),
          borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
        ),
        child: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
            child: BlocBuilder<MapRoutesBloc, MapRoutesState>(
              builder: (context, state) {
                return SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Center(
                        child: Container(
                          width: 42,
                          height: 4,
                          decoration: BoxDecoration(
                            color: const Color(0xFFB8B4A8),
                            borderRadius: BorderRadius.circular(999),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Container(
                            width: 52,
                            height: 52,
                            decoration: BoxDecoration(
                              color: const Color(0xFFEAF1F8),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Icon(
                              _transportTypeIcon(transportType),
                              color: const Color(0xFF1C4F7A),
                              size: 28,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              _transportTypeLabel(transportType),
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w800,
                                color: Color(0xFF17324D),
                              ),
                            ),
                          ),
                          IconButton(
                            onPressed: () => Navigator.of(context).pop(),
                            icon: const Icon(
                              Icons.close,
                              color: Color(0xFFD64545),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      if (state.isLoading && state.availableRoutes.isEmpty)
                        const LinearProgressIndicator(),
                      if (state.selectedRoutes.isNotEmpty) ...[
                        Text(
                          'Вибрані: ${state.selectedRoutes.map((route) => route.shortName).join(', ')}',
                          style: const TextStyle(
                            color: Color(0xFF17324D),
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 10),
                      ],
                      SizedBox(
                        height: 220,
                        child: GridView.builder(
                          itemCount: state.availableRoutes.length,
                          gridDelegate:
                              const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 4,
                                mainAxisSpacing: 10,
                                crossAxisSpacing: 10,
                                childAspectRatio: 1.6,
                              ),
                          itemBuilder: (context, index) {
                            final route = state.availableRoutes[index];
                            final selected =
                                state.selectedRoutes.contains(route);
                            return InkWell(
                              onTap: () => onRouteTap(route),
                              borderRadius: BorderRadius.circular(14),
                              child: Ink(
                                decoration: BoxDecoration(
                                  color: selected
                                      ? const Color(0xFF1C4F7A)
                                      : Colors.white,
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border.all(
                                    color: selected
                                        ? const Color(0xFF1C4F7A)
                                        : Colors.black.withValues(alpha: 0.08),
                                  ),
                                ),
                                child: Center(
                                  child: Text(
                                    route.shortName,
                                    style: TextStyle(
                                      color: selected
                                          ? Colors.white
                                          : const Color(0xFF17324D),
                                      fontWeight: FontWeight.w800,
                                      fontSize: 20,
                                    ),
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: 14),
                      const Divider(height: 1),
                      const SizedBox(height: 14),
                      Text(
                        'План A/B',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF17324D),
                        ),
                      ),
                      const SizedBox(height: 10),
                      RoutePlanningPanel(
                        createPointSelectBloc: createPointSelectBloc,
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

String _transportTypeLabel(int transportType) {
  return switch (transportType) {
    0 => 'Міські автобуси',
    1 => 'Тролейбуси',
    2 => 'Трамваї',
    3 => 'Маршрутні таксі',
    _ => 'Інший транспорт',
  };
}

IconData _transportTypeIcon(int transportType) {
  return switch (transportType) {
    0 => Icons.directions_bus,
    1 => Icons.electric_bolt,
    2 => Icons.tram,
    3 => Icons.airport_shuttle,
    _ => Icons.alt_route,
  };
}
