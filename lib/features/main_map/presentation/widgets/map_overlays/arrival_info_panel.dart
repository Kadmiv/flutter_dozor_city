import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_dozor_city/core/domain/entities/arrival_info.dart';
import 'package:flutter_dozor_city/core/domain/entities/route_arrival.dart';
import 'package:flutter_dozor_city/features/main_map/presentation/bloc/map_arrivals_cubit.dart';

class ArrivalInfoPanel extends StatelessWidget {
  const ArrivalInfoPanel({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<MapArrivalsCubit, MapArrivalsState>(
      builder: (context, state) {
        final arrival = state.arrivalInfo;
        if (arrival == null) {
          return const SizedBox.shrink();
        }

        final richArrivals = arrival.routeArrivals;
        return DecoratedBox(
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.96),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: Colors.black.withValues(alpha: 0.08)),
          ),
          child: Padding(
            padding: const EdgeInsets.all(10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.access_time,
                      size: 16,
                      color: Color(0xFF17324D),
                    ),
                    const SizedBox(width: 6),
                    const Text(
                      'Прибуття транспорту',
                      style: TextStyle(
                        color: Color(0xFF17324D),
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const Spacer(),
                    if (state.activeZoneId != null)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEAF1F8),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          state.activeZoneId!,
                          style: const TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF17324D),
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 10),
                if (richArrivals.isNotEmpty)
                  Column(
                    children: [
                      ...richArrivals.map(
                        (item) => Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: _RouteArrivalTile(arrival: item),
                        ),
                      ),
                    ],
                  )
                else
                  _FallbackMinutesTable(arrival: arrival),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _RouteArrivalTile extends StatelessWidget {
  const _RouteArrivalTile({required this.arrival});

  final RouteArrival arrival;

  @override
  Widget build(BuildContext context) {
    final routeColor = _routeColorFromText(arrival.routeShortName);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: const Color(0xFFF7FAFC),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.black.withValues(alpha: 0.05)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
        child: Row(
          children: [
            Container(
              width: 34,
              height: 34,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: routeColor,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                arrival.routeShortName,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${arrival.minute} хв',
                    style: const TextStyle(
                      color: Color(0xFF17324D),
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    arrival.busName,
                    style: const TextStyle(
                      color: Color(0xFF4E6378),
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _routeColorFromText(String value) {
    final hash = value.runes.fold<int>(0, (sum, rune) => sum + rune);
    final colors = <Color>[
      const Color(0xFF1C4F7A),
      const Color(0xFF0F766E),
      const Color(0xFFB45309),
      const Color(0xFF7C3AED),
      const Color(0xFFBE185D),
    ];
    return colors[hash % colors.length];
  }
}

class _FallbackMinutesTable extends StatelessWidget {
  const _FallbackMinutesTable({required this.arrival});

  final ArrivalInfo arrival;

  @override
  Widget build(BuildContext context) {
    return Table(
      columnWidths: const {
        0: IntrinsicColumnWidth(),
        1: FlexColumnWidth(),
        2: FlexColumnWidth(),
      },
      defaultVerticalAlignment: TableCellVerticalAlignment.middle,
      children: [
        _headerRow(),
        _dataRow(
          icon: Icons.directions_bus,
          name: 'Автобус',
          values: arrival.busMinutes,
        ),
        _dataRow(
          icon: Icons.electric_bolt,
          name: 'Тролейбус',
          values: arrival.trolleyMinutes,
        ),
        _dataRow(
          icon: Icons.tram,
          name: 'Трамвай',
          values: arrival.tramMinutes,
        ),
      ],
    );
  }

  static TableRow _headerRow() {
    return const TableRow(
      children: [
        SizedBox.shrink(),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 6, vertical: 3),
          child: Text(
            'Тип',
            style: TextStyle(
              color: Color(0xFF17324D),
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 6, vertical: 3),
          child: Text(
            'Хвилини',
            style: TextStyle(
              color: Color(0xFF17324D),
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }

  static TableRow _dataRow({
    required IconData icon,
    required String name,
    required List<int> values,
  }) {
    final text = values.isEmpty ? '—' : values.join(', ');
    return TableRow(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 5),
          child: Icon(icon, size: 18, color: const Color(0xFF1C4F7A)),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 5),
          child: Text(
            name,
            style: const TextStyle(
              color: Color(0xFF17324D),
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 5),
          child: Text(
            text,
            style: const TextStyle(
              color: Color(0xFF17324D),
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}
