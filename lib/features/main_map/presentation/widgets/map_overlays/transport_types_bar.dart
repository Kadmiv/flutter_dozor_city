import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_dozor_city/features/main_map/presentation/bloc/main_map_cubit.dart';
import 'package:flutter_dozor_city/features/main_map/presentation/bloc/map_routes_cubit.dart';

class TransportTypesBar extends StatelessWidget {
  const TransportTypesBar({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<MapRoutesBloc, MapRoutesState>(
      builder: (context, state) {
        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            children: List.generate(5, (index) {
              return ChoiceChip(
                label: Text('Тип ${index + 1}'),
                selected: state.transportType == index,
                onSelected: (_) {
                  final cityId = context.read<MainMapBloc>().state.city?.id;
                  if (cityId == null) {
                    return;
                  }
                  context.read<MainMapBloc>()
                    ..setRouteMode(MainMapMode.routes)
                    ..setActiveMapActionLabel('Тип транспорту ${index + 1}');
                  context.read<MapRoutesBloc>().selectTransportType(
                        cityId: cityId,
                        type: index,
                      );
                },
              );
            }),
          ),
        );
      },
    );
  }
}
