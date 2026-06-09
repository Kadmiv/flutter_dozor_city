import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_dozor_city/core/map/map_controller.dart';
import 'package:flutter_dozor_city/features/main_map/presentation/bloc/main_map_cubit.dart';
import 'package:flutter_dozor_city/features/main_map/presentation/bloc/map_routes_cubit.dart';
import 'package:flutter_dozor_city/features/main_map/presentation/bloc/map_arrivals_cubit.dart';
import 'package:flutter_dozor_city/features/main_map/presentation/bloc/map_stops_cubit.dart';
import 'package:flutter_dozor_city/features/live_tracking/presentation/bloc/live_tracking_cubit.dart';

class MapStateListener extends StatelessWidget {
  const MapStateListener({
    super.key,
    required this.mapController,
    required this.child,
  });

  final MapController mapController;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return MultiBlocListener(
      listeners: [
        BlocListener<MainMapBloc, MainMapState>(
          listenWhen: (previous, current) => previous.camera != current.camera,
          listener: (context, state) {
            final camera = state.camera;
            if (camera != null) {
              mapController.setCamera(camera);
            }
          },
        ),
        BlocListener<MapRoutesBloc, MapRoutesState>(
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
        BlocListener<MapArrivalsBloc, MapArrivalsState>(
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
        BlocListener<MapStopsBloc, MapStopsState>(
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
        BlocListener<LiveTrackingBloc, LiveTrackingState>(
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
      child: child,
    );
  }
}
