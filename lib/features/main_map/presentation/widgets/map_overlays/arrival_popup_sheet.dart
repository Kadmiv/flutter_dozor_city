import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_dozor_city/features/main_map/presentation/bloc/map_arrivals_cubit.dart';
import 'package:flutter_dozor_city/features/main_map/presentation/widgets/map_overlays/arrival_info_panel.dart';

class ArrivalPopupSheet extends StatelessWidget {
  const ArrivalPopupSheet({
    super.key,
    required this.title,
  });

  final String title;

  @override
  Widget build(BuildContext context) {
    return FractionallySizedBox(
      heightFactor: 0.58,
      child: DecoratedBox(
        decoration: const BoxDecoration(
          color: Color(0xFFF5F0E5),
          borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
        ),
        child: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
            child: BlocBuilder<MapArrivalsBloc, MapArrivalsState>(
              builder: (context, state) {
                return Column(
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
                        Expanded(
                          child: Text(
                            title,
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
                    const SizedBox(height: 12),
                    if (state.isLoading && state.arrivalInfo == null)
                      const Expanded(
                        child: Center(child: CircularProgressIndicator()),
                      )
                    else if (state.arrivalInfo == null)
                      const Expanded(
                        child: Center(
                          child: Text(
                            'Немає даних про прибуття',
                            style: TextStyle(
                              color: Color(0xFF4E6378),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      )
                    else
                      const Expanded(
                        child: SingleChildScrollView(
                          child: ArrivalInfoPanel(),
                        ),
                      ),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}
