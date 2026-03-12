import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_dozor_city/core/di/injector.dart';
import 'package:flutter_dozor_city/core/domain/entities/selected_point.dart';
import 'package:flutter_dozor_city/core/domain/repositories/search_repository.dart';
import 'package:flutter_dozor_city/core/router/app_route_names.dart';
import 'package:flutter_dozor_city/features/point_select/domain/usecases/get_current_location_use_case.dart';
import 'package:flutter_dozor_city/features/point_select/domain/usecases/search_address_suggestions_use_case.dart';
import 'package:flutter_dozor_city/features/point_select/presentation/bloc/point_select_cubit.dart';
import 'package:flutter_dozor_city/features/point_select/presentation/pages/point_select_page.dart';
import 'package:flutter_dozor_city/features/route_search/presentation/bloc/route_search_cubit.dart';
import 'package:go_router/go_router.dart';

class RouteSearchPage extends StatefulWidget {
  const RouteSearchPage({super.key, required this.cubit});

  final RouteSearchCubit cubit;

  @override
  State<RouteSearchPage> createState() => _RouteSearchPageState();
}

class _RouteSearchPageState extends State<RouteSearchPage> {
  @override
  void initState() {
    super.initState();
    widget.cubit.loadDraft();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: widget.cubit,
      child: BlocBuilder<RouteSearchCubit, RouteSearchState>(
        builder: (context, state) {
          return SingleChildScrollView(
            padding: const EdgeInsets.only(bottom: 12),
            child: Column(
              children: [
                DecoratedBox(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                      color: Colors.black.withValues(alpha: 0.06),
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(12, 12, 10, 10),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            children: [
                              _LegacyPointRow(
                                label: 'Від',
                                value: state.start?.label ??
                                    'Натисніть щоб обрати адресу',
                                onTap: () => _pickPoint(context, isStart: true),
                              ),
                              const SizedBox(height: 8),
                              _LegacyPointRow(
                                label: 'До',
                                value: state.end?.label ??
                                    'Натисніть щоб обрати адресу',
                                onTap: () =>
                                    _pickPoint(context, isStart: false),
                              ),
                              const SizedBox(height: 10),
                              Wrap(
                                spacing: 6,
                                runSpacing: 6,
                                children: List.generate(5, (index) {
                                  final icon = switch (index) {
                                    0 => Icons.directions_bus,
                                    1 => Icons.tram,
                                    2 => Icons.electric_bolt,
                                    3 => Icons.directions_railway,
                                    _ => Icons.route,
                                  };
                                  return _LegacyTransportToggle(
                                    icon: icon,
                                    selected:
                                        state.transportTypes.contains(index),
                                    onTap: () => context
                                        .read<RouteSearchCubit>()
                                        .toggleTransportType(index),
                                  );
                                }),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 10),
                        Column(
                          children: [
                            _SideActionButton(
                              icon: Icons.swap_vert,
                              onTap: () =>
                                  context.read<RouteSearchCubit>().swap(),
                            ),
                            const SizedBox(height: 6),
                            _SideActionButton(
                              icon: Icons.search,
                              onTap: () {
                                final params =
                                    context.read<RouteSearchCubit>().validate();
                                if (params == null) {
                                  return;
                                }
                                context.goNamed(
                                  AppRouteNames.results,
                                  extra: params,
                                );
                              },
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                if (state.errorText != null) ...[
                  const SizedBox(height: 12),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      state.errorText!,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.error,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          );
        },
      ),
    );
  }

  Future<void> _pickPoint(BuildContext context, {required bool isStart}) async {
    final point = await showDialog<SelectedPoint>(
      context: context,
      builder: (_) => PointSelectPage(
        cubit: PointSelectCubit(
          searchAddressSuggestionsUseCase: SearchAddressSuggestionsUseCase(
            injector<SearchRepository>(),
          ),
          getCurrentLocationUseCase: GetCurrentLocationUseCase(
            injector<SearchRepository>(),
          ),
        ),
      ),
    );

    if (point == null || !context.mounted) {
      return;
    }

    final cubit = context.read<RouteSearchCubit>();
    if (isStart) {
      cubit.setStart(point);
    } else {
      cubit.setEnd(point);
    }
  }
}

class _LegacyPointRow extends StatelessWidget {
  const _LegacyPointRow({
    required this.label,
    required this.value,
    required this.onTap,
  });

  final String label;
  final String value;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(
          width: 28,
          child: Text(
            label,
            style: const TextStyle(
              color: Color(0xFF17324D),
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        const SizedBox(width: 6),
        Expanded(
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(10),
            child: Ink(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFF1C4F7A),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      value,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  const Icon(
                    Icons.chevron_right,
                    color: Colors.white,
                    size: 16,
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _LegacyTransportToggle extends StatelessWidget {
  const _LegacyTransportToggle({
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Ink(
        width: 34,
        height: 34,
        decoration: BoxDecoration(
          color: selected ? const Color(0xFF1C4F7A) : const Color(0xFFE5EDF5),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(
          icon,
          size: 18,
          color: selected ? Colors.white : const Color(0xFF17324D),
        ),
      ),
    );
  }
}

class _SideActionButton extends StatelessWidget {
  const _SideActionButton({
    required this.icon,
    required this.onTap,
  });

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Ink(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: const Color(0xFFF0EBDD),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.black.withValues(alpha: 0.06)),
        ),
        child: Icon(icon, size: 20, color: const Color(0xFF17324D)),
      ),
    );
  }
}
