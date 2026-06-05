import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_dozor_city/core/domain/entities/city.dart';
import 'package:flutter_dozor_city/core/domain/entities/transport_route.dart';
import 'package:flutter_dozor_city/core/domain/entities/vehicle.dart';
import 'package:flutter_dozor_city/core/map/app_map_camera.dart';
import 'package:flutter_dozor_city/core/map/map_controller.dart';
import 'package:flutter_dozor_city/features/city_selection/presentation/bloc/city_selection_cubit.dart';
import 'package:flutter_dozor_city/features/city_selection/presentation/widgets/city_picker_content.dart';
import 'package:flutter_dozor_city/features/live_tracking/presentation/bloc/live_tracking_cubit.dart';
import 'package:flutter_dozor_city/features/live_tracking/presentation/widgets/vehicle_details_sheet.dart';
import 'package:flutter_dozor_city/features/main_map/presentation/bloc/main_map_cubit.dart';
import 'package:flutter_dozor_city/features/main_map/presentation/bloc/map_arrivals_cubit.dart';
import 'package:flutter_dozor_city/features/main_map/presentation/bloc/map_overlays_cubit.dart';
import 'package:flutter_dozor_city/features/main_map/presentation/bloc/map_routes_cubit.dart';
import 'package:flutter_dozor_city/features/main_map/presentation/pages/main_map_page.dart';
import 'package:flutter_dozor_city/features/main_map/presentation/widgets/map_overlays/routes_sheet.dart';
import 'package:flutter_dozor_city/features/main_map/presentation/widgets/map_overlays/stops_sheet.dart';
import 'package:flutter_dozor_city/features/route_preview/presentation/bloc/route_preview_cubit.dart';

class MainMapOrchestrator extends StatefulWidget {
  const MainMapOrchestrator({
    super.key,
    required this.mainMapCubit,
    required this.liveTrackingCubit,
    required this.mapOverlaysCubit,
    required this.mapRoutesCubit,
    required this.mapArrivalsCubit,
    required this.routePreviewCubit,
    required this.mapController,
    required this.createCitySelectionCubit,
    required this.child,
  });

  final MainMapCubit mainMapCubit;
  final LiveTrackingCubit liveTrackingCubit;
  final MapOverlaysCubit mapOverlaysCubit;
  final MapRoutesCubit mapRoutesCubit;
  final MapArrivalsCubit mapArrivalsCubit;
  final RoutePreviewCubit routePreviewCubit;
  final MapController mapController;
  final CitySelectionCubit Function() createCitySelectionCubit;
  final Widget child;

  @override
  State<MainMapOrchestrator> createState() => _MainMapOrchestratorState();
}

class _MainMapOrchestratorState extends State<MainMapOrchestrator> {
  @override
  void initState() {
    super.initState();
    _bootstrapMainMap();
  }

  Future<void> _bootstrapMainMap() async {
    await widget.mainMapCubit.refresh();
    final city = widget.mainMapCubit.state.city;
    if (city == null || !mounted) {
      return;
    }
    await widget.mapRoutesCubit.restoreForCity(city.id);
    await widget.liveTrackingCubit.start(
      city.id,
      routeIds: _selectedRouteIdsOrNull(),
    );
    final camera = widget.mainMapCubit.state.camera;
    if (camera != null) {
      await widget.mapController.setCamera(camera);
    }
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
    widget.mapArrivalsCubit.reset();
    widget.mainMapCubit
      ..setRouteMode(MainMapMode.routes)
      ..setActiveMapActionLabel('Місто ${selectedCity.name}');
    await widget.mainMapCubit.refresh(forceCityCenter: true);
    await widget.mapRoutesCubit.restoreForCity(selectedCity.id);
    await widget.liveTrackingCubit.start(
      selectedCity.id,
      routeIds: _selectedRouteIdsOrNull(),
    );
    await widget.mapController.setCamera(
      widget.mainMapCubit.state.camera ??
          AppMapCamera(
            centerLat: selectedCity.centerLat,
            centerLng: selectedCity.centerLng,
            zoom: selectedCity.zoom,
          ),
    );
  }

  Future<void> _openRoutesSheet(int transportType) async {
    final cityId = widget.mainMapCubit.state.city?.id;
    if (cityId == null) {
      return;
    }
    widget.mainMapCubit
      ..setRouteMode(MainMapMode.routes)
      ..setActiveMapActionLabel(_transportTypeLabel(transportType));
    widget.mapArrivalsCubit.clearZones();
    await widget.mapRoutesCubit.selectTransportType(
      cityId: cityId,
      type: transportType,
    );
    await widget.liveTrackingCubit.updateFilters(_selectedRouteIdsOrNull());
    if (!mounted) {
      return;
    }
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (sheetContext) => BlocProvider.value(
        value: widget.mapRoutesCubit,
        child: RoutesSheet(
          transportType: transportType,
          onRouteTap: (route) async {
            await widget.mapRoutesCubit.selectRoute(
              cityId: cityId,
              route: route,
            );
            widget.mapArrivalsCubit.clearZones();
            _syncRouteLabel();
            await widget.liveTrackingCubit.updateFilters(
              _selectedRouteIdsOrNull(),
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
    await widget.mapRoutesCubit.setActiveRoute(cityId: cityId, route: route);
    await widget.mapArrivalsCubit.loadZones(cityId: cityId, routeId: route.id);
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
        value: widget.mapArrivalsCubit,
        child: StopsSheet(
          route: route,
          onZoneTap: (zoneId, zoneName) async {
            await widget.mapArrivalsCubit.loadArrival(
              cityId: cityId,
              zoneId: zoneId,
            );
            widget.mainMapCubit.setActiveMapActionLabel('Зупинка $zoneName');
          },
        ),
      ),
    );
  }

  String _transportTypeLabel(int type) {
    switch (type) {
      case 0:
        return 'Автобуси';
      case 1:
        return 'Тролейбуси';
      case 2:
        return 'Трамваї';
      default:
        return 'Маршрути';
    }
  }

  List<String>? _selectedRouteIdsOrNull() {
    final routeIds = widget.mapRoutesCubit.state.selectedRoutes
        .map((route) => route.id)
        .toList(growable: false);
    if (routeIds.isEmpty) {
      return null;
    }
    return routeIds;
  }

  void _syncRouteLabel() {
    final selectedRoutes = widget.mapRoutesCubit.state.selectedRoutes;
    widget.mainMapCubit.setActiveMapActionLabel(
      selectedRoutes.isEmpty
          ? 'Маршрути очищено'
          : 'Маршрут ${selectedRoutes.last.shortName}',
    );
  }

  Future<void> _removeSelectedRoute(TransportRoute route) async {
    await widget.mapRoutesCubit.removeRoute(route.id);
    widget.mapArrivalsCubit.clearZones();
    _syncRouteLabel();
    await widget.liveTrackingCubit.updateFilters(_selectedRouteIdsOrNull());
  }

  Future<void> _openVehicleSheet(Vehicle vehicle) async {
    final routeColorValue = _routeColorValueFor(vehicle.routeId);
    if (!mounted) {
      return;
    }
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (sheetContext) => VehicleDetailsSheet(
        vehicle: vehicle,
        routeColorValue: routeColorValue,
      ),
    );
  }

  int _routeColorValueFor(String routeId) {
    for (final route in widget.mapRoutesCubit.state.selectedRoutes) {
      if (route.id == routeId) {
        return route.lineColorValue;
      }
    }
    for (final route in widget.mapRoutesCubit.state.availableRoutes) {
      if (route.id == routeId) {
        return route.lineColorValue;
      }
    }
    return 0xFFC8102E;
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider.value(value: widget.mainMapCubit),
        BlocProvider.value(value: widget.liveTrackingCubit),
        BlocProvider.value(value: widget.mapOverlaysCubit),
        BlocProvider.value(value: widget.mapRoutesCubit),
        BlocProvider.value(value: widget.mapArrivalsCubit),
        BlocProvider.value(value: widget.routePreviewCubit),
      ],
      child: MainMapPage(
        mapController: widget.mapController,
        onOpenCityPicker: _openCityPicker,
        onOpenRoutesSheet: _openRoutesSheet,
        onOpenStopsSheet: _openStopsSheet,
        onRemoveSelectedRoute: _removeSelectedRoute,
        onOpenVehicleSheet: _openVehicleSheet,
        child: widget.child,
      ),
    );
  }
}
