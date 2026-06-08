import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_dozor_city/core/domain/entities/app_display_language.dart';
import 'package:flutter_dozor_city/core/domain/entities/transport_route.dart';
import 'package:flutter_dozor_city/core/domain/entities/vehicle.dart';
import 'package:flutter_dozor_city/core/map/app_map_camera.dart';
import 'package:flutter_dozor_city/core/map/map_controller.dart';
import 'package:flutter_dozor_city/core/router/app_route_names.dart';
import 'package:flutter_dozor_city/core/domain/entities/route_status_filter.dart';
import 'package:flutter_dozor_city/features/live_tracking/domain/entities/animated_vehicle.dart';
import 'package:flutter_dozor_city/features/live_tracking/presentation/bloc/live_tracking_cubit.dart';
import 'package:flutter_dozor_city/features/main_map/presentation/bloc/main_map_cubit.dart';
import 'package:flutter_dozor_city/features/main_map/presentation/bloc/map_arrivals_cubit.dart';
import 'package:flutter_dozor_city/features/main_map/presentation/bloc/map_language_cubit.dart';
import 'package:flutter_dozor_city/features/main_map/presentation/bloc/map_overlays_cubit.dart';
import 'package:flutter_dozor_city/features/main_map/presentation/bloc/map_route_planning_cubit.dart';
import 'package:flutter_dozor_city/features/main_map/presentation/bloc/map_routes_cubit.dart';
import 'package:flutter_dozor_city/features/main_map/presentation/bloc/map_stops_cubit.dart';
import 'package:flutter_dozor_city/features/main_map/presentation/widgets/map_overlays/arrival_popup_sheet.dart';
import 'package:flutter_dozor_city/features/main_map/presentation/widgets/map_state_listener.dart';
import 'package:flutter_dozor_city/features/route_preview/presentation/bloc/route_preview_cubit.dart';
import 'package:flutter_dozor_city/features/route_preview/presentation/widgets/route_preview_map_layer.dart';
import 'package:flutter_dozor_city/features/route_preview/presentation/widgets/route_preview_panel.dart';
import 'package:go_router/go_router.dart';

part '../widgets/main_map_components.dart';

class MainMapPage extends StatelessWidget {
  const MainMapPage({
    super.key,
    required this.mapController,
    required this.onOpenCityPicker,
    required this.onOpenRoutesSheet,
    required this.onOpenStopsSheet,
    required this.onRemoveSelectedRoute,
    required this.onOpenVehicleSheet,
    required this.child,
  });

  final MapController mapController;
  final VoidCallback onOpenCityPicker;
  final ValueChanged<int> onOpenRoutesSheet;
  final ValueChanged<TransportRoute> onOpenStopsSheet;
  final Future<void> Function(TransportRoute route) onRemoveSelectedRoute;
  final ValueChanged<Vehicle> onOpenVehicleSheet;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return MapStateListener(
      mapController: mapController,
      child: Scaffold(
        body: SafeArea(
          bottom: false,
          child: _MapShell(
            mapController: mapController,
            onOpenCityPicker: onOpenCityPicker,
            onOpenRoutesSheet: onOpenRoutesSheet,
            onOpenStopsSheet: onOpenStopsSheet,
            onRemoveSelectedRoute: onRemoveSelectedRoute,
            onOpenVehicleSheet: onOpenVehicleSheet,
            child: child,
          ),
        ),
      ),
    );
  }
}

class _MapShell extends StatelessWidget {
  const _MapShell({
    required this.mapController,
    required this.onOpenCityPicker,
    required this.onOpenRoutesSheet,
    required this.onOpenStopsSheet,
    required this.onRemoveSelectedRoute,
    required this.onOpenVehicleSheet,
    required this.child,
  });

  final MapController mapController;
  final VoidCallback onOpenCityPicker;
  final ValueChanged<int> onOpenRoutesSheet;
  final ValueChanged<TransportRoute> onOpenStopsSheet;
  final Future<void> Function(TransportRoute route) onRemoveSelectedRoute;
  final ValueChanged<Vehicle> onOpenVehicleSheet;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<MainMapCubit, MainMapState>(
      builder: (context, state) {
        return Stack(
          children: [
            Positioned.fill(
              child: BlocBuilder<MainMapCubit, MainMapState>(
                builder: (context, mainMapState) {
                  return BlocBuilder<MapRoutesCubit, MapRoutesState>(
                    builder: (context, routesState) {
                      return BlocBuilder<LiveTrackingCubit, LiveTrackingState>(
                        builder: (context, trackingState) {
                          return BlocBuilder<MapStopsCubit, MapStopsState>(
                            builder: (context, stopsState) {
                              return BlocBuilder<
                                MapRoutePlanningCubit,
                                MapRoutePlanningState
                              >(
                                builder: (context, planningState) {
                                  final selectedRoutes = routesState
                                      .selectedRoutes
                                      .map((route) => route.id)
                                      .toSet();
                                  final routeColorsById = <String, int>{
                                    for (final route
                                        in routesState.availableRoutes)
                                      route.id: route.lineColorValue,
                                    for (final route
                                        in routesState.selectedRoutes)
                                      route.id: route.lineColorValue,
                                  };
                                  final hasTypeScopedRoutes =
                                      routesState.availableRoutes.isNotEmpty;
                                  final selectedStatus =
                                      routesState.selectedStatus;
                                  final statusValue =
                                      selectedStatus.statusValue;
                                  final List<AnimatedVehicle> visibleVehicles =
                                      !mainMapState.showMarkers
                                      ? const <AnimatedVehicle>[]
                                      : selectedRoutes.isEmpty
                                      ? hasTypeScopedRoutes
                                            ? trackingState.animatedVehicles
                                                  .where(
                                                    (vehicle) =>
                                                        vehicle
                                                            .vehicle
                                                            .transportType ==
                                                        routesState
                                                            .transportType,
                                                  )
                                                  .where(
                                                    (vehicle) => _matchesStatus(
                                                      vehicle
                                                          .vehicle
                                                          .routeStatus,
                                                      statusValue,
                                                    ),
                                                  )
                                                  .toList(growable: false)
                                            : trackingState.animatedVehicles
                                                  .where(
                                                    (vehicle) => _matchesStatus(
                                                      vehicle
                                                          .vehicle
                                                          .routeStatus,
                                                      statusValue,
                                                    ),
                                                  )
                                                  .toList(growable: false)
                                      : trackingState.animatedVehicles
                                            .where(
                                              (vehicle) =>
                                                  selectedRoutes.contains(
                                                    vehicle.vehicle.routeId,
                                                  ),
                                            )
                                            .where(
                                              (vehicle) => _matchesStatus(
                                                vehicle.vehicle.routeStatus,
                                                statusValue,
                                              ),
                                            )
                                            .toList(growable: false);
                                  return RoutePreviewMapLayer(
                                    mapController: mapController,
                                    vehicles: visibleVehicles,
                                    selectedRoutesCount:
                                        routesState.selectedRoutes.length,
                                    routeColorsById: routeColorsById,
                                    cityStops: stopsState.cityStops,
                                    showMarkers: mainMapState.showMarkers,
                                    onVehicleTap: onOpenVehicleSheet,
                                    onCityStopTap: (stop) async {
                                      final cityId = mainMapState.city?.id;
                                      if (cityId == null) {
                                        return;
                                      }
                                      final arrivalsCubit = context
                                          .read<MapArrivalsCubit>();
                                      final mainMapCubit = context
                                          .read<MainMapCubit>();
                                      final language = context
                                          .read<MapLanguageCubit>()
                                          .state
                                          .language;
                                      unawaited(
                                        showModalBottomSheet<void>(
                                          context: context,
                                          backgroundColor: Colors.transparent,
                                          isScrollControlled: true,
                                          builder: (sheetContext) =>
                                              BlocProvider.value(
                                                value: arrivalsCubit,
                                                child: ArrivalPopupSheet(
                                                  title: stop.displayName(
                                                    language,
                                                  ),
                                                ),
                                              ),
                                        ),
                                      );
                                      await arrivalsCubit.loadArrival(
                                        cityId: cityId,
                                        zoneId: stop.id,
                                      );
                                      mainMapCubit.setActiveMapActionLabel(
                                        'Зупинка ${stop.displayName(language)}',
                                      );
                                    },
                                    onMapTap: (point) {
                                      if (planningState.mode ==
                                          MapRoutePlanningMode.inactive) {
                                        return;
                                      }
                                      context
                                          .read<MapRoutePlanningCubit>()
                                          .setPointFromMap(point);
                                    },
                                    onCameraIdle: () {
                                      final camera = mapController.camera;
                                      context.read<MainMapCubit>().saveCamera(
                                        AppMapCamera(
                                          centerLat: camera.centerLat,
                                          centerLng: camera.centerLng,
                                          zoom: camera.zoom,
                                        ),
                                      );
                                    },
                                    routePolylines: routesState.selectedRoutes,
                                  );
                                },
                              );
                            },
                          );
                        },
                      );
                    },
                  );
                },
              ),
            ),
            // const Positioned(
            //   left: 12,
            //   right: 12,
            //   top: 12,
            //   child: _LiveStatusBanner(),
            // ),
            Positioned(
              top: 12,
              left: 12,
              right: 12,
              child: _LegacyTopMenu(onOpenCityPicker: onOpenCityPicker),
            ),
            if (!state.dismissedHints.contains('select-city'))
              Positioned(
                top: 62,
                right: 20,
                child: _HintBubble(
                  message: 'Оберіть місто або змініть його тут',
                  direction: _HintDirection.topRight,
                  onClose: () =>
                      context.read<MainMapCubit>().dismissHint('select-city'),
                ),
              ),
            Positioned(
              top: 104,
              left: 12,
              right: 12,
              child: BlocBuilder<MapRoutePlanningCubit, MapRoutePlanningState>(
                builder: (context, planningState) {
                  if (planningState.mode == MapRoutePlanningMode.inactive) {
                    return const SizedBox.shrink();
                  }
                  return _RoutePlanningPanel(state: planningState);
                },
              ),
            ),
            if (state.mode == MainMapMode.routes)
              Positioned(
                top: 174,
                left: 12,
                right: 96,
                child: _SelectedRoutesWrap(
                  onRouteTap: onOpenStopsSheet,
                  onRouteRemove: onRemoveSelectedRoute,
                ),
              ),
            // const Positioned(top: 74, right: 12, child: _MarkersMenu()),
            if (!state.dismissedHints.contains('map-menu') &&
                state.mode == MainMapMode.routes)
              Positioned(
                top: 308,
                left: 18,
                child: _HintBubble(
                  message: 'Оберіть тип транспорту та маршрут на мапі',
                  direction: _HintDirection.topLeft,
                  onClose: () =>
                      context.read<MainMapCubit>().dismissHint('map-menu'),
                ),
              ),
            // const Positioned(
            //   left: 12,
            //   bottom: 328,
            //   child: _BottomMapActions(),
            // ),
            Positioned(
              right: 12,
              bottom: 120,
              child: _LocationControl(mapController: mapController),
            ),
            if (!state.dismissedHints.contains('arrival'))
              Positioned(
                left: 18,
                bottom: 496,
                child: _HintBubble(
                  message: 'Тут з’являється прогноз прибуття по зупинці',
                  direction: _HintDirection.bottomLeft,
                  onClose: () =>
                      context.read<MainMapCubit>().dismissHint('arrival'),
                ),
              ),
            if (state.mode == MainMapMode.routes)
              Positioned(
                left: 0,
                right: 0,
                bottom: 12,
                child: _BottomTransportNavigation(onTypeTap: onOpenRoutesSheet),
              ),
            if (state.isBottomSheetVisible)
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: _BottomTabSheet(child: child),
              ),
          ],
        );
      },
    );
  }
}

bool _matchesStatus(int? routeStatus, int? selectedStatus) {
  if (selectedStatus == null) {
    return true;
  }
  if (routeStatus == null) {
    return selectedStatus == -1;
  }
  return routeStatus == selectedStatus;
}
