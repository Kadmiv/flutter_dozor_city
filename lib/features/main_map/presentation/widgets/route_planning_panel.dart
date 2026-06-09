import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_dozor_city/core/domain/entities/selected_point.dart';
import 'package:flutter_dozor_city/features/main_map/presentation/bloc/map_route_planning_cubit.dart';
import 'package:flutter_dozor_city/features/point_select/presentation/bloc/point_select_cubit.dart';

class RoutePlanningPanel extends StatelessWidget {
  const RoutePlanningPanel({super.key, required this.createPointSelectBloc});

  final PointSelectBloc Function() createPointSelectBloc;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<MapRoutePlanningBloc, MapRoutePlanningState>(
      builder: (context, state) {
        return Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.96),
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
                padding: const EdgeInsets.all(12),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(
                          Icons.route,
                          size: 18,
                          color: Color(0xFF1C4F7A),
                        ),
                        const SizedBox(width: 8),
                        const Expanded(
                          child: Text(
                            'Побудова маршруту',
                            style: TextStyle(
                              color: Color(0xFF17324D),
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                        IconButton(
                          onPressed: () =>
                              context.read<MapRoutePlanningBloc>().cancel(),
                          icon: const Icon(Icons.close, size: 18),
                          tooltip: 'Завершити',
                          visualDensity: VisualDensity.compact,
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      state.mode == MapRoutePlanningMode.selectingStart
                          ? 'Торкніться карти, щоб вибрати старт'
                          : state.mode == MapRoutePlanningMode.selectingEnd
                          ? 'Торкніться карти, щоб вибрати фініш'
                          : 'Оберіть пункти, або натисніть пошук',
                      style: TextStyle(
                        color: Colors.black.withValues(alpha: 0.68),
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 10),
                    FilledButton.tonalIcon(
                      onPressed: () =>
                          context.read<MapRoutePlanningBloc>().startPlanning(),
                      icon: const Icon(Icons.map_outlined, size: 18),
                      label: const Text('Обрати на мапі A → B'),
                    ),
                    const SizedBox(height: 10),
                    _RoutePlanningPointField(
                      label: 'Від',
                      hint: 'Введіть стартову точку',
                      value: state.start,
                      createPointSelectBloc: createPointSelectBloc,
                      onSelected: (point) =>
                          context.read<MapRoutePlanningBloc>().setStart(point),
                    ),
                    const SizedBox(height: 8),
                    _RoutePlanningPointField(
                      label: 'До',
                      hint: 'Введіть фінішну точку',
                      value: state.end,
                      createPointSelectBloc: createPointSelectBloc,
                      onSelected: (point) =>
                          context.read<MapRoutePlanningBloc>().setEnd(point),
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: List.generate(5, (index) {
                        final selected = state.transportTypes.contains(index);
                        return _TransportMiniToggle(
                          icon: _transportTypeIcon(index),
                          selected: selected,
                          onTap: () => context
                              .read<MapRoutePlanningBloc>()
                              .toggleTransportType(index),
                        );
                      }),
                    ),
                    const SizedBox(height: 10),
                    if (state.isLoading)
                      const LinearProgressIndicator(minHeight: 2),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        _RoundActionButton(
                          icon: Icons.swap_vert,
                          onTap: () =>
                              context.read<MapRoutePlanningBloc>().swap(),
                        ),
                        const SizedBox(width: 8),
                        _RoundActionButton(
                          icon: Icons.search,
                          onTap: () =>
                              context.read<MapRoutePlanningBloc>().search(),
                        ),
                        const SizedBox(width: 8),
                        _RoundActionButton(
                          icon: Icons.delete_outline,
                          onTap: () =>
                              context.read<MapRoutePlanningBloc>().clear(),
                        ),
                        const Spacer(),
                        Text(
                          state.results.isEmpty
                              ? '0 варіантів'
                              : '${state.results.length} варіантів',
                          style: const TextStyle(
                            color: Color(0xFF17324D),
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                    if (state.results.isNotEmpty) ...[
                      const SizedBox(height: 10),
                      SizedBox(
                        height: 40,
                        child: ListView.separated(
                          scrollDirection: Axis.horizontal,
                          itemCount: state.results.length,
                          separatorBuilder: (context, index) =>
                              const SizedBox(width: 8),
                          itemBuilder: (context, index) {
                            final result = state.results[index];
                            final active = state.activeResult?.id == result.id;
                            return InkWell(
                              onTap: () => context
                                  .read<MapRoutePlanningBloc>()
                                  .selectResult(result),
                              borderRadius: BorderRadius.circular(12),
                              child: Ink(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 8,
                                ),
                                decoration: BoxDecoration(
                                  color: active
                                      ? const Color(0xFF1C4F7A)
                                      : const Color(0xFFEAF1F8),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      result.title,
                                      style: TextStyle(
                                        color: active
                                            ? Colors.white
                                            : const Color(0xFF17324D),
                                        fontSize: 12,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                    if (result.totalTravelMinutes != null) ...[
                                      const SizedBox(width: 6),
                                      Text(
                                        '${result.totalTravelMinutes} хв',
                                        style: TextStyle(
                                          color: active
                                              ? Colors.white.withValues(
                                                  alpha: 0.86,
                                                )
                                              : const Color(0xFF1C4F7A),
                                          fontSize: 11,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                    if (state.failure != null) ...[
                      const SizedBox(height: 8),
                      Text(
                        state.failure!.message,
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.error,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _RoutePlanningPointField extends StatefulWidget {
  const _RoutePlanningPointField({
    required this.label,
    required this.hint,
    required this.value,
    required this.createPointSelectBloc,
    required this.onSelected,
  });

  final String label;
  final String hint;
  final SelectedPoint? value;
  final PointSelectBloc Function() createPointSelectBloc;
  final ValueChanged<SelectedPoint> onSelected;

  @override
  State<_RoutePlanningPointField> createState() =>
      _RoutePlanningPointFieldState();
}

class _RoutePlanningPointFieldState extends State<_RoutePlanningPointField> {
  late final PointSelectBloc _bloc = widget.createPointSelectBloc();
  late final TextEditingController _controller = TextEditingController(
    text: widget.value?.label ?? '',
  );
  late final FocusNode _focusNode = FocusNode();

  @override
  void didUpdateWidget(covariant _RoutePlanningPointField oldWidget) {
    super.didUpdateWidget(oldWidget);
    final nextText = widget.value?.label ?? '';
    if (!_focusNode.hasFocus && _controller.text != nextText) {
      _controller.text = nextText;
    }
  }

  @override
  void dispose() {
    _focusNode.dispose();
    _controller.dispose();
    _bloc.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: _bloc,
      child: BlocConsumer<PointSelectBloc, PointSelectState>(
        listenWhen: (previous, current) =>
            previous.selectedPoint != current.selectedPoint &&
            current.selectedPoint != null,
        listener: (context, state) {
          final point = state.selectedPoint;
          if (point == null) {
            return;
          }
          widget.onSelected(point);
          _controller.text = point.label;
          _focusNode.unfocus();
        },
        builder: (context, state) {
          final showSuggestions =
              _focusNode.hasFocus && state.suggestions.isNotEmpty;
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  SizedBox(
                    width: 28,
                    child: Text(
                      widget.label,
                      style: const TextStyle(
                        color: Color(0xFF17324D),
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      focusNode: _focusNode,
                      onChanged: (value) {
                        _bloc.add(PointSelectQueryChanged(value));
                        setState(() {});
                      },
                      onTap: () => setState(() {}),
                      decoration: InputDecoration(
                        hintText: widget.hint,
                        isDense: true,
                        filled: true,
                        fillColor: const Color(0xFFF4F7FA),
                        prefixIcon: const Icon(Icons.search, size: 18),
                        suffixIcon: IconButton(
                          icon: const Icon(Icons.my_location, size: 18),
                          tooltip: 'Поточна геопозиція',
                          onPressed: () {
                            _bloc.add(
                              const PointSelectCurrentLocationRequested(),
                            );
                            setState(() {});
                          },
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 12,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              if (showSuggestions) ...[
                const SizedBox(height: 6),
                ConstrainedBox(
                  constraints: const BoxConstraints(maxHeight: 160),
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: Colors.black.withValues(alpha: 0.08),
                      ),
                    ),
                    child: ListView.separated(
                      padding: const EdgeInsets.all(8),
                      shrinkWrap: true,
                      itemCount: state.suggestions.length,
                      separatorBuilder: (context, index) =>
                          const SizedBox(height: 6),
                      itemBuilder: (context, index) {
                        final point = state.suggestions[index];
                        final icon = switch (point.source) {
                          SelectedPointSource.zone => Icons.place_outlined,
                          SelectedPointSource.address => Icons.location_on,
                          SelectedPointSource.gps => Icons.my_location,
                          SelectedPointSource.mapTap => Icons.map,
                        };
                        final subtitle = switch (point.source) {
                          SelectedPointSource.zone => 'Зупинка',
                          SelectedPointSource.address => 'Адреса',
                          SelectedPointSource.gps => 'Геопозиція',
                          SelectedPointSource.mapTap => 'Точка на мапі',
                        };
                        return InkWell(
                          borderRadius: BorderRadius.circular(12),
                          onTap: () =>
                              _bloc.add(PointSelectSuggestionSelected(point)),
                          child: Ink(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 9,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF4F7FA),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: 28,
                                  height: 28,
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Icon(
                                    icon,
                                    size: 16,
                                    color: const Color(0xFF1C4F7A),
                                  ),
                                ),
                                const SizedBox(width: 9),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        point.label,
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        subtitle,
                                        style: TextStyle(
                                          fontSize: 11,
                                          color: Colors.black.withValues(
                                            alpha: 0.56,
                                          ),
                                        ),
                                      ),
                                    ],
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
              ],
            ],
          );
        },
      ),
    );
  }
}

class _RoundActionButton extends StatelessWidget {
  const _RoundActionButton({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return IconButton.filledTonal(
      onPressed: onTap,
      icon: Icon(icon),
      visualDensity: VisualDensity.compact,
      tooltip: switch (icon) {
        Icons.swap_vert => 'Поміняти місцями',
        Icons.search => 'Пошук',
        Icons.delete_outline => 'Очистити',
        _ => '',
      },
    );
  }
}

class _TransportMiniToggle extends StatelessWidget {
  const _TransportMiniToggle({
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
      borderRadius: BorderRadius.circular(12),
      onTap: onTap,
      child: Ink(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFF1C4F7A) : const Color(0xFFEAF1F8),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(
          icon,
          size: 17,
          color: selected ? Colors.white : const Color(0xFF1C4F7A),
        ),
      ),
    );
  }
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
