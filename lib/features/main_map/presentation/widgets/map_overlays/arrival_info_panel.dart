import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_dozor_city/features/main_map/presentation/bloc/map_overlays_cubit.dart';

class ArrivalInfoPanel extends StatelessWidget {
  const ArrivalInfoPanel({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<MapOverlaysCubit, MapOverlaysState>(
      builder: (context, state) {
        final arrival = state.arrivalInfo;
        if (arrival == null) {
          return const SizedBox.shrink();
        }

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
                const SizedBox(height: 8),
                Table(
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
                ),
              ],
            ),
          ),
        );
      },
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
