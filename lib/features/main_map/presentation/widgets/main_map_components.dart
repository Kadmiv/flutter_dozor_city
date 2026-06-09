// ignore_for_file: unused_element

part of '../pages/main_map_page.dart';

class _LegacyTopMenu extends StatelessWidget {
  const _LegacyTopMenu({
    required this.onOpenCityPicker,
    required this.onOpenStopSearch,
  });

  final VoidCallback onOpenCityPicker;
  final Future<void> Function() onOpenStopSearch;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<MainMapBloc, MainMapState>(
      builder: (context, state) {
        final cityName = state.city?.name ?? 'Оберіть місто';
        return BlocBuilder<MapLanguageBloc, MapLanguageState>(
          builder: (context, languageState) {
            return BlocBuilder<MapRoutesBloc, MapRoutesState>(
              builder: (context, routesState) {
                final statusLabel = switch (routesState.selectedStatus) {
                  RouteStatusFilter.all => 'All',
                  RouteStatusFilter.status1 => '1',
                  RouteStatusFilter.status2 => '2',
                  RouteStatusFilter.unknown => '?',
                };
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
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 6,
                    ),
                    child: Row(
                      children: [
                        _TopMenuChip(
                          key: const Key('top-menu-city'),
                          icon: Icons.location_city,
                          label: cityName,
                          onTap: onOpenCityPicker,
                        ),
                        const SizedBox(width: 8),
                        _TopMenuChip(
                          key: const Key('top-menu-routes'),
                          icon: state.mode == MainMapMode.routes
                              ? Icons.alt_route
                              : Icons.map_outlined,
                          label: state.mode == MainMapMode.routes
                              ? 'Маршрути'
                              : 'Місто',
                          isActive: state.mode == MainMapMode.routes,
                          onTap: () {
                            context.read<MainMapBloc>()
                              ..setRouteMode(MainMapMode.routes)
                              ..openBottomSheet(
                                tab: MainMapTab.search,
                              );
                          },
                        ),
                        const SizedBox(width: 8),
                        _TopMenuChip(
                          key: const Key('top-menu-status'),
                          icon: Icons.tune,
                          label: 'Статус $statusLabel',
                          onTap: () {
                            final next = switch (routesState.selectedStatus) {
                              RouteStatusFilter.all =>
                                RouteStatusFilter.status1,
                              RouteStatusFilter.status1 =>
                                RouteStatusFilter.status2,
                              RouteStatusFilter.status2 =>
                                RouteStatusFilter.unknown,
                              RouteStatusFilter.unknown =>
                                RouteStatusFilter.all,
                            };
                            context.read<MapRoutesBloc>().setStatusFilter(
                              next,
                            );
                          },
                        ),
                        const SizedBox(width: 8),
                        _TopMenuChip(
                          key: const Key('top-menu-language'),
                          icon: Icons.language,
                          label:
                              languageState.language == AppDisplayLanguage.en
                              ? 'EN'
                              : 'KA',
                          onTap: () {
                            context.read<MapLanguageBloc>().toggle();
                          },
                        ),
                        const SizedBox(width: 8),
                        IconButton(
                          onPressed: () {
                            unawaited(onOpenStopSearch());
                          },
                          icon: const Icon(
                            Icons.search,
                            color: Colors.white,
                          ),
                          tooltip: 'Пошук зупинки',
                        ),
                        const Spacer(),
                        IconButton(
                          onPressed: onOpenCityPicker,
                          icon: const Icon(
                            Icons.sync_alt,
                            color: Colors.white,
                          ),
                          tooltip: 'Змінити місто',
                        ),
                      ],
                    ),
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

class _TopMenuChip extends StatelessWidget {
  const _TopMenuChip({
    super.key,
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
  const _SelectedRoutesWrap({
    required this.onRouteTap,
    required this.onRouteRemove,
  });

  final ValueChanged<TransportRoute> onRouteTap;
  final Future<void> Function(TransportRoute route) onRouteRemove;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<MapRoutesBloc, MapRoutesState>(
      builder: (context, state) {
        if (state.selectedRoutes.isEmpty) {
          return const SizedBox.shrink();
        }
        return BlocBuilder<MapLanguageBloc, MapLanguageState>(
          builder: (context, languageState) {
            return Align(
              alignment: Alignment.topLeft,
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 320),
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
                  child: SizedBox(
                    height: 56,
                    child: ListView.separated(
                      padding: const EdgeInsets.all(10),
                      scrollDirection: Axis.horizontal,
                      itemCount: state.selectedRoutes.length,
                      separatorBuilder: (context, index) =>
                          const SizedBox(width: 8),
                      itemBuilder: (context, index) {
                        final route = state.selectedRoutes[index];
                        final selected = state.activeRouteId == route.id;
                        final routeColor = Color(route.lineColorValue);
                        return InkWell(
                          onTap: () => onRouteTap(route),
                          borderRadius: BorderRadius.circular(16),
                          child: Ink(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: routeColor.withValues(
                                alpha: selected ? 0.28 : 0.14,
                              ),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: routeColor.withValues(alpha: 0.28),
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  route.displayShortName(
                                    languageState.language,
                                  ),
                                  style: TextStyle(
                                    color: routeColor,
                                    fontWeight: FontWeight.w800,
                                    fontSize: 14,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                InkWell(
                                  onTap: () async {
                                    await onRouteRemove(route);
                                  },
                                  borderRadius: BorderRadius.circular(999),
                                  child: const Icon(
                                    Icons.close,
                                    size: 16,
                                    color: Color(0xFFD64545),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}

class _RoundActionButton extends StatelessWidget {
  const _RoundActionButton({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Ink(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: const Color(0xFF1C4F7A).withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Icon(icon, color: const Color(0xFF1C4F7A)),
      ),
    );
  }
}

class _BottomTransportNavigation extends StatelessWidget {
  const _BottomTransportNavigation({required this.onTypeTap});

  final ValueChanged<int> onTypeTap;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<MapRoutesBloc, MapRoutesState>(
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
            child: BlocBuilder<MapRoutesBloc, MapRoutesState>(
              builder: (context, state) {
                return BlocBuilder<MapLanguageBloc, MapLanguageState>(
                  builder: (context, languageState) {
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
                            'Вибрані: ${state.selectedRoutes.map((route) => route.displayShortName(languageState.language)).join(', ')}',
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
                              final selected = state.selectedRoutes.contains(
                                route,
                              );
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
                                          : Colors.black.withValues(
                                              alpha: 0.08,
                                            ),
                                    ),
                                  ),
                                  child: Center(
                                    child: Text(
                                      route.displayShortName(
                                        languageState.language,
                                      ),
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
            child: BlocBuilder<MapArrivalsBloc, MapArrivalsState>(
              builder: (context, state) {
                return BlocBuilder<MapLanguageBloc, MapLanguageState>(
                  builder: (context, languageState) {
                    return BlocBuilder<MapRoutesBloc, MapRoutesState>(
                      builder: (context, routesState) {
                        final visibleZones = state.routeZones
                            .where(
                              (zone) => _matchesStatus(
                                zone.status,
                                routesState.selectedStatus.statusValue,
                              ),
                            )
                            .toList(growable: false);
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
                                    'Зупинки маршруту № ${route.displayShortName(languageState.language)}',
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
                                child: Center(
                                  child: CircularProgressIndicator(),
                                ),
                              )
                            else
                              Expanded(
                                child: ListView.separated(
                                  itemCount: visibleZones.length,
                                  separatorBuilder: (context, index) =>
                                      const SizedBox(height: 8),
                                  itemBuilder: (context, index) {
                                    final zone = visibleZones[index];
                                    return InkWell(
                                      onTap: () => onZoneTap(
                                        zone.id,
                                        zone.displayName(
                                          languageState.language,
                                        ),
                                      ),
                                      borderRadius: BorderRadius.circular(16),
                                      child: Ink(
                                        padding: const EdgeInsets.all(10),
                                        decoration: BoxDecoration(
                                          color: Colors.white,
                                          borderRadius: BorderRadius.circular(
                                            16,
                                          ),
                                          border: Border.all(
                                            color: Colors.black.withValues(
                                              alpha: 0.08,
                                            ),
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
                                                borderRadius:
                                                    BorderRadius.circular(10),
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
                                                zone.displayName(
                                                  languageState.language,
                                                ),
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
                    );
                  },
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

class _MarkersMenu extends StatelessWidget {
  const _MarkersMenu();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<MainMapBloc, MainMapState>(
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
                  onPressed: () => context.read<MainMapBloc>().toggleMarkers(),
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
  const _LocationControl({required this.mapController});

  final MapController mapController;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<LiveTrackingBloc, LiveTrackingState>(
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
        return DecoratedBox(
          decoration: decoration,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(18),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _MapControlButton(
                  icon: Icons.add,
                  tooltip: 'Збільшити масштаб',
                  onPressed: () {
                    mapController.zoomBy(1);
                  },
                ),
                Divider(
                  height: 1,
                  thickness: 1,
                  color: Colors.white.withValues(alpha: 0.12),
                ),
                _MapControlButton(
                  icon: Icons.remove,
                  tooltip: 'Зменшити масштаб',
                  onPressed: () {
                    mapController.zoomBy(-1);
                  },
                ),
                Divider(
                  height: 1,
                  thickness: 1,
                  color: Colors.white.withValues(alpha: 0.12),
                ),
                SizedBox(
                  width: 52,
                  height: 52,
                  child: state.isLoading
                      ? const Center(
                          child: SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          ),
                        )
                      : IconButton(
                          onPressed: () {},
                          icon: const Icon(
                            Icons.my_location,
                            color: Colors.white,
                          ),
                          tooltip: 'Моє місце',
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

class _MapControlButton extends StatelessWidget {
  const _MapControlButton({
    required this.icon,
    required this.tooltip,
    required this.onPressed,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 52,
      height: 52,
      child: IconButton(
        onPressed: onPressed,
        icon: Icon(icon, color: Colors.white),
        tooltip: tooltip,
        splashRadius: 24,
      ),
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
                      context.read<MainMapBloc>().closeBottomSheet(),
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
    return BlocBuilder<MainMapBloc, MainMapState>(
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
                      context.read<MainMapBloc>().openBottomSheet(
                        tab: MainMapTab.search,
                      );
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
                      context.read<MainMapBloc>().openBottomSheet(
                        tab: MainMapTab.results,
                      );
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
                      context.read<MainMapBloc>().openBottomSheet(
                        tab: MainMapTab.stored,
                      );
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

class _LiveStatusBanner extends StatelessWidget {
  const _LiveStatusBanner();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<MainMapBloc, MainMapState>(
      builder: (context, mainMapState) {
        return BlocBuilder<MapRoutesBloc, MapRoutesState>(
          builder: (context, routesState) {
            return BlocBuilder<LiveTrackingBloc, LiveTrackingState>(
              builder: (context, trackingState) {
                final updatedAt = trackingState.lastUpdatedAt;
                final updatedLabel = updatedAt == null
                    ? 'ще не оновлювалось'
                    : '${updatedAt.hour.toString().padLeft(2, '0')}:'
                          '${updatedAt.minute.toString().padLeft(2, '0')}:'
                          '${updatedAt.second.toString().padLeft(2, '0')}';
                final selectedRoutes = routesState.selectedRoutes
                    .map((route) => route.id)
                    .toSet();
                final hasTypeScopedRoutes =
                    routesState.availableRoutes.isNotEmpty;
                final visibleCount = !mainMapState.showMarkers
                    ? 0
                    : selectedRoutes.isEmpty
                    ? hasTypeScopedRoutes
                          ? trackingState.vehicles
                                .where(
                                  (vehicle) =>
                                      vehicle.transportType ==
                                      routesState.transportType,
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
