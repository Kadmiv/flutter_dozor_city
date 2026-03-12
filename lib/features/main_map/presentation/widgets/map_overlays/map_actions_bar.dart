import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_dozor_city/core/domain/entities/search_params.dart';
import 'package:flutter_dozor_city/core/router/app_route_names.dart';
import 'package:flutter_dozor_city/features/main_map/presentation/bloc/main_map_cubit.dart';
import 'package:go_router/go_router.dart';

class MapActionsBar extends StatelessWidget {
  const MapActionsBar({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<MainMapCubit, MainMapState>(
      builder: (context, state) {
        return Row(
          children: [
            FilledButton.tonalIcon(
              onPressed: () => context.read<MainMapCubit>().toggleMarkers(),
              icon: Icon(
                state.showMarkers ? Icons.visibility : Icons.visibility_off,
              ),
              label: Text(
                state.showMarkers ? 'Маркери увімкнені' : 'Маркери вимкнені',
              ),
            ),
            const SizedBox(width: 12),
            OutlinedButton.icon(
              onPressed: () {
                final extra = context.mounted
                    ? GoRouterState.of(context).extra as SearchParams?
                    : null;
                if (extra != null) {
                  context.goNamed(AppRouteNames.results, extra: extra);
                }
              },
              icon: const Icon(Icons.alt_route),
              label: const Text('Показати preview'),
            ),
          ],
        );
      },
    );
  }
}
