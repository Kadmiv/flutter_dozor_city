import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_dozor_city/core/domain/entities/city.dart';
import 'package:flutter_dozor_city/core/domain/entities/transport_route.dart';
import 'package:flutter_dozor_city/core/map/app_map_camera.dart';
import 'package:flutter_dozor_city/core/map/map_controller.dart';
import 'package:flutter_dozor_city/core/router/app_route_names.dart';
import 'package:flutter_dozor_city/features/city_selection/presentation/bloc/city_selection_cubit.dart';
import 'package:flutter_dozor_city/features/city_selection/presentation/widgets/city_picker_content.dart';
import 'package:flutter_dozor_city/features/live_tracking/domain/entities/vehicle_entity.dart';
import 'package:flutter_dozor_city/features/live_tracking/presentation/bloc/live_tracking_cubit.dart';
import 'package:flutter_dozor_city/features/main_map/presentation/bloc/main_map_cubit.dart';
import 'package:flutter_dozor_city/features/main_map/presentation/bloc/map_overlays_cubit.dart';
import 'package:flutter_dozor_city/features/main_map/presentation/widgets/map_overlays/arrival_info_panel.dart';
import 'package:flutter_dozor_city/features/route_preview/presentation/bloc/route_preview_cubit.dart';
import 'package:flutter_dozor_city/features/route_preview/presentation/widgets/route_preview_map_layer.dart';
import 'package:flutter_dozor_city/features/route_preview/presentation/widgets/route_preview_panel.dart';
import 'package:go_router/go_router.dart';

class MainMapPage extends StatefulWidget {
  const MainMapPage({
    super.key,
    required this.mainMapCubit,
    required this.liveTrackingCubit,
    required this.overlaysCubit,
    required this.routePreviewCubit,
    required this.mapController,
    required this.createCitySelectionCubit,
    required this.child,
  });

  final MainMapCubit mainMapCubit;
  final LiveTrackingCubit liveTrackingCubit;
  final MapOverlaysCubit overlaysCubit;
  final RoutePreviewCubit routePreviewCubit;
  final MapController mapController;
  final CitySelectionCubit Function() createCitySelectionCubit;
  final Widget child;

  @override
  State<MainMapPage> createState() => _MainMapPageState();
}

class _MainMapPageState extends State<MainMapPage> {
  @override
  void initState() {
    super.initState();
    widget.mainMapCubit.refresh().then((_) {
      final cityId = widget.mainMapCubit.state.city?.id;
      final camera = widget.mainMapCubit.state.camera;
      if (cityId != null) {
        widget.liveTrackingCubit.start(cityId);
      }
      if (camera != null) {
        widget.mapController.setCamera(camera);
      }
    });
  }

  @override
  void dispose() {
    widget.liveTrackingCubit.stop();
    super.dispose();
  }

  Future<void> _openCityPicker() async {
    final cubit = widget.createCitySelectionCubit();
    await cubit.loadCities();
    if (!mounted) {
      await cubit.close();
      return;
    }
    final selectedCity = await showModalBottomSheet<City>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => BlocProvider.value(
        value: cubit,
        child: FractionallySizedBox(
          key: const Key('city-picker-sheet'),
          heightFactor: 0.60,
          child: DecoratedBox(
            decoration: const BoxDecoration(
              color: Color(0xFFF5F0E5),
              borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
            ),
            child: CityPickerContent(
              showHeader: false,
              title: 'Вибір міста',
              onCityTapOverride: (context, city) async {
                await context.read<CitySelectionCubit>().selectCity(city);
                if (context.mounted) {
                  Navigator.of(context).pop(city);
                }
              },
            ),
          ),
        ),
      ),
    );
    await cubit.close();
    if (selectedCity == null || !mounted) {
      return;
    }
    widget.routePreviewCubit.clear();
    widget.overlaysCubit.reset();
    widget.mainMapCubit
      ..setRouteMode(MainMapMode.city)
      ..closeBottomSheet()
      ..setActiveMapActionLabel('Місто ${selectedCity.name}');
    await widget.mainMapCubit.refresh();
    widget.liveTrackingCubit
      ..stop()
      ..start(selectedCity.id);
    final camera = widget.mainMapCubit.state.camera;
    if (camera != null) {
      widget.mapController.setCamera(camera);
    }
  }

  Future<void> _openRoutesSheet(int transportType) async {
    final cityId = widget.mainMapCubit.state.city?.id;
    if (cityId == null) {
      return;
    }
    widget.mainMapCubit
      ..setRouteMode(MainMapMode.routes)
      ..setActiveMapActionLabel(_transportTypeLabel(transportType));
    await widget.overlaysCubit.selectTransportType(
      cityId: cityId,
      type: transportType,
    );
    if (!mounted) {
      return;
    }
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (sheetContext) => BlocProvider.value(
        value: widget.overlaysCubit,
        child: _RoutesSheet(
          transportType: transportType,
          onRouteTap: (route) async {
            await widget.overlaysCubit.selectRoute(
              cityId: cityId,
              route: route,
            );
            widget.mainMapCubit.setActiveMapActionLabel(
              'Маршрут ${route.shortName}',
            );
          },
        ),
      ),
    );
  }

  Future<void> _openStopsSheet(TransportRoute route) async {
    final cityId = widget.mainMapCubit.state.city?.id;
    if (cityId == null) {
      return;
    }
    await widget.overlaysCubit.setActiveRoute(cityId: cityId, route: route);
    widget.mainMapCubit.setActiveMapActionLabel(
      'Зупинки маршруту ${route.shortName}',
    );
    if (!mounted) {
      return;
    }
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (sheetContext) => BlocProvider.value(
        value: widget.overlaysCubit,
        child: _StopsSheet(
          route: route,
          onZoneTap: (zoneId, zoneName) async {
            await widget.overlaysCubit.loadArrival(
              cityId: cityId,
              zoneId: zoneId,
            );
            widget.mainMapCubit.setActiveMapActionLabel('Зупинка $zoneName');
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider.value(value: widget.mainMapCubit),
        BlocProvider.value(value: widget.liveTrackingCubit),
        BlocProvider.value(value: widget.overlaysCubit),
        BlocProvider.value(value: widget.routePreviewCubit),
      ],
      child: MultiBlocListener(
        listeners: [
          BlocListener<RoutePreviewCubit, RoutePreviewState>(
            listenWhen: (previous, current) =>
                previous.camera != current.camera && current.camera != null,
            listener: (context, state) {
              final previewCamera = state.camera;
              if (previewCamera != null) {
                widget.mapController.setCamera(previewCamera);
              }
            },
          ),
          BlocListener<MapOverlaysCubit, MapOverlaysState>(
            listenWhen: (previous, current) =>
                previous.selectedRoutes != current.selectedRoutes,
            listener: (context, state) {
              final routeIds =
                  state.selectedRoutes.map((route) => route.id).toList();
              widget.liveTrackingCubit.updateFilters(
                routeIds.isEmpty ? null : routeIds,
              );
            },
          ),
        ],
        child: Scaffold(
          body: SafeArea(
            bottom: false,
            child: _MapShell(
              mapController: widget.mapController,
              onOpenCityPicker: _openCityPicker,
              onOpenRoutesSheet: _openRoutesSheet,
              onOpenStopsSheet: _openStopsSheet,
              child: widget.child,
            ),
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
    required this.child,
  });

  final MapController mapController;
  final VoidCallback onOpenCityPicker;
  final ValueChanged<int> onOpenRoutesSheet;
  final ValueChanged<TransportRoute> onOpenStopsSheet;
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
                  return BlocBuilder<MapOverlaysCubit, MapOverlaysState>(
                    builder: (context, overlaysState) {
                      return BlocBuilder<LiveTrackingCubit, LiveTrackingState>(
                        builder: (context, trackingState) {
                          final selectedRoutes = overlaysState.selectedRoutes
                              .map((route) => route.id)
                              .toSet();
                          final hasTypeScopedRoutes =
                              overlaysState.availableRoutes.isNotEmpty;
                          final List<VehicleEntity> visibleVehicles =
                              !mainMapState.showMarkers
                              ? const <VehicleEntity>[]
                              : selectedRoutes.isEmpty
                              ? hasTypeScopedRoutes
                                    ? trackingState.vehicles
                                          .where(
                                            (vehicle) =>
                                                vehicle.transportType ==
                                                overlaysState.transportType,
                                          )
                                          .toList(growable: false)
                                    : trackingState.vehicles
                              : trackingState.vehicles
                                    .where(
                                      (vehicle) => selectedRoutes.contains(
                                        vehicle.routeId,
                                      ),
                                    )
                                    .toList(growable: false);
                          return RoutePreviewMapLayer(
                            mapController: mapController,
                            vehicles: visibleVehicles,
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
            if (state.mode == MainMapMode.routes)
              Positioned(
                top: 74,
                left: 12,
                right: 96,
                child: _SelectedRoutesWrap(onRouteTap: onOpenStopsSheet),
              ),
            // const Positioned(top: 74, right: 12, child: _MarkersMenu()),
            if (!state.dismissedHints.contains('map-menu') &&
                state.mode == MainMapMode.routes)
              Positioned(
                top: 208,
                left: 18,
                child: _HintBubble(
                  message: 'Оберіть тип транспорту та маршрут на мапі',
                  direction: _HintDirection.topLeft,
                  onClose: () =>
                      context.read<MainMapCubit>().dismissHint('map-menu'),
                ),
              ),
            const Positioned(
              left: 12,
              right: 12,
              top: 138,
              child: _ArrivalOverlayCard(),
            ),
            // const Positioned(
            //   left: 12,
            //   bottom: 328,
            //   child: _BottomMapActions(),
            // ),
            const Positioned(right: 12, bottom: 120, child: _LocationControl()),
            if (!state.dismissedHints.contains('arrival'))
              Positioned(
                left: 18,
                bottom: 396,
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

class _LegacyTopMenu extends StatelessWidget {
  const _LegacyTopMenu({required this.onOpenCityPicker});

  final VoidCallback onOpenCityPicker;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<MainMapCubit, MainMapState>(
      builder: (context, state) {
        final cityName = state.city?.name ?? 'Оберіть місто';
        return DecoratedBox(
          decoration: BoxDecoration(
            color: const Color(0xFF1C4F7A),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.16),
                blurRadius: 18,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            child: Row(
              children: [
                _TopMenuChip(
                  icon: Icons.location_city,
                  label: cityName,
                  onTap: () {
                    context.read<MainMapCubit>().setRouteMode(MainMapMode.city);
                    onOpenCityPicker();
                  },
                ),
                const SizedBox(width: 8),
                // const _AlarmIndicator(),
                const SizedBox(width: 8),
                _TopMenuChip(
                  icon: state.mode == MainMapMode.routes
                      ? Icons.alt_route
                      : Icons.map_outlined,
                  label: state.mode == MainMapMode.routes
                      ? 'Маршрути'
                      : 'Місто',
                  isActive: state.mode == MainMapMode.routes,
                  onTap: () {
                    context.read<MainMapCubit>().setRouteMode(
                      MainMapMode.routes,
                    );
                    context.read<MainMapCubit>().openBottomSheet(
                      tab: MainMapTab.search,
                    );
                    context.goNamed(AppRouteNames.search);
                  },
                ),
                const Spacer(),
                IconButton(
                  onPressed: () {
                    context.read<MainMapCubit>().setRouteMode(MainMapMode.city);
                    onOpenCityPicker();
                  },
                  icon: const Icon(Icons.sync_alt, color: Colors.white),
                  tooltip: 'Змінити місто',
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _TopMenuChip extends StatelessWidget {
  const _TopMenuChip({
    required this.icon,
    required this.label,
    required this.onTap,
    this.isActive = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool isActive;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: onTap,
      child: Ink(
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 7),
        decoration: BoxDecoration(
          color: isActive
              ? const Color(0xFFFFCF5A).withValues(alpha: 0.24)
              : Colors.white.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: Colors.white, size: 17),
            const SizedBox(width: 6),
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 112),
              child: Text(
                label,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
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

class _SelectedRoutesWrap extends StatelessWidget {
  const _SelectedRoutesWrap({required this.onRouteTap});

  final ValueChanged<TransportRoute> onRouteTap;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<MapOverlaysCubit, MapOverlaysState>(
      builder: (context, state) {
        if (state.selectedRoutes.isEmpty) {
          return const SizedBox.shrink();
        }
        return Align(
          alignment: Alignment.topLeft,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 280),
            child: DecoratedBox(
              key: const Key('selected-routes-wrap'),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.94),
                borderRadius: BorderRadius.circular(18),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.14),
                    blurRadius: 20,
                    offset: const Offset(0, 12),
                  ),
                ],
              ),
              child: Padding(
                padding: const EdgeInsets.all(10),
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: state.selectedRoutes
                      .map(
                        (route) => InputChip(
                          label: Text(route.shortName),
                          selected: state.activeRouteId == route.id,
                          onPressed: () => onRouteTap(route),
                          onDeleted: () async {
                            await context.read<MapOverlaysCubit>().removeRoute(
                              route.id,
                            );
                            if (!context.mounted) {
                              return;
                            }
                            final remaining = context
                                .read<MapOverlaysCubit>()
                                .state
                                .selectedRoutes;
                            context
                                .read<MainMapCubit>()
                                .setActiveMapActionLabel(
                                  remaining.isEmpty
                                      ? 'Маршрути очищено'
                                      : 'Маршрут ${remaining.last.shortName}',
                                );
                          },
                          backgroundColor: Color(
                            route.lineColorValue,
                          ).withValues(alpha: 0.14),
                          selectedColor: Color(
                            route.lineColorValue,
                          ).withValues(alpha: 0.3),
                          labelStyle: TextStyle(
                            fontWeight: FontWeight.w700,
                            color: Color(route.lineColorValue),
                          ),
                          deleteIconColor: const Color(0xFFD64545),
                        ),
                      )
                      .toList(growable: false),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _BottomTransportNavigation extends StatelessWidget {
  const _BottomTransportNavigation({required this.onTypeTap});

  final ValueChanged<int> onTypeTap;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<MapOverlaysCubit, MapOverlaysState>(
      builder: (context, state) {
        return Center(
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: const Color(0xFF1C4F7A),
              borderRadius: BorderRadius.circular(22),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.18),
                  blurRadius: 18,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: List.generate(5, (index) {
                  final selected = state.transportType == index;
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: InkWell(
                      onTap: () => onTypeTap(index),
                      borderRadius: BorderRadius.circular(16),
                      child: Ink(
                        key: Key('transport-type-$index'),
                        width: 52,
                        height: 52,
                        decoration: BoxDecoration(
                          color: selected
                              ? Colors.white.withValues(alpha: 0.2)
                              : Colors.white.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Icon(
                          _transportTypeIcon(index),
                          color: Colors.white,
                        ),
                      ),
                    ),
                  );
                }),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _RoutesSheet extends StatelessWidget {
  const _RoutesSheet({required this.transportType, required this.onRouteTap});

  final int transportType;
  final ValueChanged<TransportRoute> onRouteTap;

  @override
  Widget build(BuildContext context) {
    return FractionallySizedBox(
      key: const Key('routes-sheet'),
      heightFactor: 0.54,
      child: DecoratedBox(
        decoration: const BoxDecoration(
          color: Color(0xFFF5F0E5),
          borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
        ),
        child: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
            child: BlocBuilder<MapOverlaysCubit, MapOverlaysState>(
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
                    Expanded(
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
                          final selected = state.selectedRoutes.contains(route);
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

class _StopsSheet extends StatelessWidget {
  const _StopsSheet({required this.route, required this.onZoneTap});

  final TransportRoute route;
  final Future<void> Function(String zoneId, String zoneName) onZoneTap;

  @override
  Widget build(BuildContext context) {
    return FractionallySizedBox(
      key: const Key('stops-sheet'),
      heightFactor: 0.72,
      child: DecoratedBox(
        decoration: const BoxDecoration(
          color: Color(0xFFF5F0E5),
          borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
        ),
        child: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
            child: BlocBuilder<MapOverlaysCubit, MapOverlaysState>(
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
                            'Зупинки маршруту № ${route.shortName}',
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
                    const SizedBox(height: 6),
                    const Text(
                      'Натисніть на назву зупинки, щоб відкрити час прибуття транспорту',
                      style: TextStyle(
                        color: Color(0xFFD48A2B),
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 12),
                    if (state.isLoading && state.routeZones.isEmpty)
                      const Expanded(
                        child: Center(child: CircularProgressIndicator()),
                      )
                    else
                      Expanded(
                        child: ListView.separated(
                          itemCount: state.routeZones.length,
                          separatorBuilder: (context, index) =>
                              const SizedBox(height: 8),
                          itemBuilder: (context, index) {
                            final zone = state.routeZones[index];
                            return InkWell(
                              onTap: () => onZoneTap(zone.id, zone.name),
                              borderRadius: BorderRadius.circular(16),
                              child: Ink(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                    color: Colors.black.withValues(alpha: 0.08),
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    Container(
                                      width: 34,
                                      height: 34,
                                      alignment: Alignment.center,
                                      decoration: BoxDecoration(
                                        color: const Color(0xFF1C4F7A),
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: Text(
                                        '${index + 1}',
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.w800,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Text(
                                        zone.name,
                                        style: const TextStyle(
                                          color: Color(0xFF17324D),
                                          fontWeight: FontWeight.w700,
                                          fontSize: 16,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
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

class _ArrivalOverlayCard extends StatelessWidget {
  const _ArrivalOverlayCard();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<MapOverlaysCubit, MapOverlaysState>(
      builder: (context, state) {
        if (state.arrivalInfo == null) {
          return const SizedBox.shrink();
        }
        return Align(
          alignment: Alignment.topLeft,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 340),
            child: const ArrivalInfoPanel(),
          ),
        );
      },
    );
  }
}

class _MarkersMenu extends StatelessWidget {
  const _MarkersMenu();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<MainMapCubit, MainMapState>(
      builder: (context, state) {
        return DecoratedBox(
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.94),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.14),
                blurRadius: 20,
                offset: const Offset(0, 12),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(10),
            child: Column(
              children: [
                IconButton(
                  onPressed: () => context.read<MainMapCubit>().toggleMarkers(),
                  icon: Icon(
                    state.showMarkers ? Icons.visibility : Icons.visibility_off,
                    color: const Color(0xFF17324D),
                  ),
                  tooltip: 'Міські маркери',
                ),
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEAF1F8),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    state.showMarkers ? 'Маркери' : 'Приховано',
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF17324D),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _LocationControl extends StatelessWidget {
  const _LocationControl();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<LiveTrackingCubit, LiveTrackingState>(
      builder: (context, state) {
        final decoration = BoxDecoration(
          color: const Color(0xFF1C4F7A),
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.18),
              blurRadius: 18,
              offset: const Offset(0, 10),
            ),
          ],
        );
        if (state.isLoading) {
          return DecoratedBox(
            decoration: decoration.copyWith(color: const Color(0xFF466B8C)),
            child: const SizedBox(
              width: 52,
              height: 52,
              child: Center(
                child: SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          );
        }
        return DecoratedBox(
          decoration: decoration,
          child: IconButton(
            onPressed: () {},
            icon: const Icon(Icons.my_location, color: Colors.white),
            tooltip: 'Моє місце',
          ),
        );
      },
    );
  }
}

class _BottomTabSheet extends StatelessWidget {
  const _BottomTabSheet({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: const Color(0xFFF5F0E5),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.18),
            blurRadius: 24,
            offset: const Offset(0, -8),
          ),
        ],
      ),
      child: SizedBox(
        height: 316,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
          child: Column(
            children: [
              Container(
                width: 42,
                height: 4,
                decoration: BoxDecoration(
                  color: const Color(0xFFB8B4A8),
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
              Align(
                alignment: Alignment.topRight,
                child: IconButton(
                  onPressed: () =>
                      context.read<MainMapCubit>().closeBottomSheet(),
                  icon: const Icon(
                    Icons.keyboard_arrow_down_rounded,
                    color: Color(0xFF17324D),
                  ),
                  tooltip: 'Закрити панель',
                ),
              ),
              const SizedBox(height: 4),
              const _TopModeBar(),
              const SizedBox(height: 12),
              const RoutePreviewPanel(),
              const SizedBox(height: 12),
              Expanded(child: child),
            ],
          ),
        ),
      ),
    );
  }
}

class _TopModeBar extends StatelessWidget {
  const _TopModeBar();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<MainMapCubit, MainMapState>(
      builder: (context, state) {
        return DecoratedBox(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
          ),
          child: Padding(
            padding: const EdgeInsets.all(6),
            child: Row(
              children: [
                Expanded(
                  child: FilledButton.tonal(
                    style: FilledButton.styleFrom(
                      backgroundColor: state.currentTab == MainMapTab.search
                          ? const Color(0xFFEAF1F8)
                          : null,
                    ),
                    onPressed: () {
                      context.read<MainMapCubit>().openBottomSheet(
                        tab: MainMapTab.search,
                      );
                      context.goNamed(AppRouteNames.search);
                    },
                    child: const Text('Пошук'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: FilledButton.tonal(
                    style: FilledButton.styleFrom(
                      backgroundColor: state.currentTab == MainMapTab.results
                          ? const Color(0xFFEAF1F8)
                          : null,
                    ),
                    onPressed: () {
                      context.read<MainMapCubit>().openBottomSheet(
                        tab: MainMapTab.results,
                      );
                      context.goNamed(AppRouteNames.results);
                    },
                    child: const Text('Результати'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: FilledButton.tonal(
                    style: FilledButton.styleFrom(
                      backgroundColor: state.currentTab == MainMapTab.stored
                          ? const Color(0xFFEAF1F8)
                          : null,
                    ),
                    onPressed: () {
                      context.read<MainMapCubit>().openBottomSheet(
                        tab: MainMapTab.stored,
                      );
                      context.goNamed(AppRouteNames.stored);
                    },
                    child: const Text('Збережені'),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _BottomMapActions extends StatelessWidget {
  const _BottomMapActions();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<MainMapCubit, MainMapState>(
      builder: (context, state) {
        return ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 220),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (state.activeMapActionLabel != null)
                Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.96),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Text(
                    state.activeMapActionLabel!,
                    style: const TextStyle(
                      color: Color(0xFF17324D),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              DecoratedBox(
                decoration: BoxDecoration(
                  color: const Color(0xFF1C4F7A),
                  borderRadius: BorderRadius.circular(18),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.18),
                      blurRadius: 18,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Padding(
                  padding: const EdgeInsets.all(8),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        onPressed: () {
                          context.read<MainMapCubit>().setActiveMapActionLabel(
                            'Режим маршрутів',
                          );
                          context
                              .read<MainMapCubit>()
                              .setRouteMode(MainMapMode.routes);
                          context.read<MainMapCubit>().selectTab(
                            MainMapTab.search,
                          );
                          context.goNamed(AppRouteNames.search);
                        },
                        icon: const Icon(Icons.alt_route, color: Colors.white),
                        tooltip: 'Маршрути',
                      ),
                      IconButton(
                        onPressed: () {
                          context.read<RoutePreviewCubit>().clear();
                          context
                              .read<MainMapCubit>()
                              .setActiveMapActionLabel('Preview очищено');
                        },
                        icon: const Icon(Icons.layers_clear, color: Colors.white),
                        tooltip: 'Очистити preview',
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _LiveStatusBanner extends StatelessWidget {
  const _LiveStatusBanner();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<MainMapCubit, MainMapState>(
      builder: (context, mainMapState) {
        return BlocBuilder<MapOverlaysCubit, MapOverlaysState>(
          builder: (context, overlaysState) {
            return BlocBuilder<LiveTrackingCubit, LiveTrackingState>(
              builder: (context, trackingState) {
                final updatedAt = trackingState.lastUpdatedAt;
                final updatedLabel = updatedAt == null
                    ? 'ще не оновлювалось'
                    : '${updatedAt.hour.toString().padLeft(2, '0')}:'
                          '${updatedAt.minute.toString().padLeft(2, '0')}:'
                          '${updatedAt.second.toString().padLeft(2, '0')}';
                final selectedRoutes = overlaysState.selectedRoutes
                    .map((route) => route.id)
                    .toSet();
                final hasTypeScopedRoutes =
                    overlaysState.availableRoutes.isNotEmpty;
                final visibleCount = !mainMapState.showMarkers
                    ? 0
                    : selectedRoutes.isEmpty
                    ? hasTypeScopedRoutes
                          ? trackingState.vehicles
                                .where(
                                  (vehicle) =>
                                      vehicle.transportType ==
                                      overlaysState.transportType,
                                )
                                .length
                          : trackingState.vehicles.length
                    : trackingState.vehicles
                          .where(
                            (vehicle) =>
                                selectedRoutes.contains(vehicle.routeId),
                          )
                          .length;
                return Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.24),
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.directions_bus, color: Colors.white),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'На карті: $visibleCount із ${trackingState.vehicles.length} • Оновлено $updatedLabel',
                          style: const TextStyle(color: Colors.white),
                        ),
                      ),
                      if (trackingState.isLoading)
                        const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                    ],
                  ),
                );
              },
            );
          },
        );
      },
    );
  }
}

enum _HintDirection { topLeft, topRight, bottomLeft }

class _HintBubble extends StatelessWidget {
  const _HintBubble({
    required this.message,
    required this.direction,
    required this.onClose,
  });

  final String message;
  final _HintDirection direction;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final arrow = switch (direction) {
      _HintDirection.topLeft => const Padding(
        padding: EdgeInsets.only(left: 14),
        child: _HintArrow(direction: _HintDirection.topLeft),
      ),
      _HintDirection.topRight => const Align(
        alignment: Alignment.topRight,
        child: Padding(
          padding: EdgeInsets.only(right: 14),
          child: _HintArrow(direction: _HintDirection.topRight),
        ),
      ),
      _HintDirection.bottomLeft => const Padding(
        padding: EdgeInsets.only(left: 14),
        child: _HintArrow(direction: _HintDirection.bottomLeft),
      ),
    };

    final body = ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 230),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: const Color(0xFFF7F8FB),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.12),
              blurRadius: 14,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 10, 8, 10),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  message,
                  style: const TextStyle(
                    color: Color(0xFF17324D),
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    height: 1.3,
                  ),
                ),
              ),
              IconButton(
                onPressed: onClose,
                icon: const Icon(Icons.close, size: 16),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                splashRadius: 16,
              ),
            ],
          ),
        ),
      ),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: direction == _HintDirection.bottomLeft
          ? [body, arrow]
          : [arrow, body],
    );
  }
}

class _HintArrow extends StatelessWidget {
  const _HintArrow({required this.direction});

  final _HintDirection direction;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: const Size(20, 10),
      painter: _HintArrowPainter(direction),
    );
  }
}

class _HintArrowPainter extends CustomPainter {
  _HintArrowPainter(this.direction);

  final _HintDirection direction;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFFF7F8FB)
      ..style = PaintingStyle.fill;
    final path = Path();
    if (direction == _HintDirection.bottomLeft) {
      path
        ..moveTo(0, 0)
        ..lineTo(size.width / 2, size.height)
        ..lineTo(size.width, 0)
        ..close();
    } else {
      path
        ..moveTo(0, size.height)
        ..lineTo(size.width / 2, 0)
        ..lineTo(size.width, size.height)
        ..close();
    }
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
