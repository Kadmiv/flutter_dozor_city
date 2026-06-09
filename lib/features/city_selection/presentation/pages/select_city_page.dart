import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_dozor_city/core/router/app_route_names.dart';
import 'package:flutter_dozor_city/features/city_selection/presentation/bloc/city_selection_cubit.dart';
import 'package:flutter_dozor_city/features/city_selection/presentation/widgets/city_picker_content.dart';
import 'package:go_router/go_router.dart';

class SelectCityPage extends StatefulWidget {
  const SelectCityPage({super.key, required this.cubit});

  final CitySelectionBloc cubit;

  @override
  State<SelectCityPage> createState() => _SelectCityPageState();
}

class _SelectCityPageState extends State<SelectCityPage> {
  @override
  void initState() {
    super.initState();
    widget.cubit.add(const CitySelectionStarted());
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: widget.cubit,
      child: MultiBlocListener(
        listeners: [
          BlocListener<CitySelectionBloc, CitySelectionState>(
            listenWhen: (previous, current) =>
                previous.submissionSucceeded != current.submissionSucceeded &&
                current.submissionSucceeded,
            listener: (context, state) {
              context.goNamed(AppRouteNames.search);
            },
          ),
          BlocListener<CitySelectionBloc, CitySelectionState>(
            listenWhen: (previous, current) =>
                previous.failure != current.failure && current.failure != null,
            listener: (context, state) {
              final failure = state.failure;
              if (failure != null) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(failure.message)),
                );
              }
            },
          ),
        ],
        child: Scaffold(
          backgroundColor: const Color(0xFFF5F0E5),
          body: CityPickerContent(
            onBack: () => context.goNamed(AppRouteNames.search),
          ),
        ),
      ),
    );
  }
}
