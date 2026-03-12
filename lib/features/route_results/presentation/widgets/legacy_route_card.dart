import 'package:flutter/material.dart';
import 'package:flutter_dozor_city/core/domain/entities/route_preview_segment.dart';
import 'package:flutter_dozor_city/core/domain/entities/route_result.dart';
import 'package:flutter_dozor_city/core/domain/entities/route_result_step.dart';

class LegacyRouteCard extends StatelessWidget {
  const LegacyRouteCard({
    super.key,
    required this.route,
    required this.leadingBadges,
    required this.onPrimaryAction,
    required this.primaryActionLabel,
    this.onSecondaryAction,
    this.secondaryActionLabel,
    this.secondaryActionIcon,
    this.trailing,
  });

  final RouteResult route;
  final List<LegacyRouteBadgeData> leadingBadges;
  final VoidCallback onPrimaryAction;
  final String primaryActionLabel;
  final VoidCallback? onSecondaryAction;
  final String? secondaryActionLabel;
  final IconData? secondaryActionIcon;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final trailingWidgets = trailing == null ? const <Widget>[] : <Widget>[trailing!];
    return Card(
      margin: EdgeInsets.zero,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: Colors.black.withValues(alpha: 0.08)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: leadingBadges
                        .map(
                          (badge) => _HeaderBadge(
                            icon: badge.icon,
                            label: badge.label,
                          ),
                        )
                        .toList(growable: false),
                  ),
                ),
                ...trailingWidgets,
              ],
            ),
            Divider(
              height: 14,
              color: const Color(0xFF1C4F7A).withValues(alpha: 0.22),
            ),
            ..._buildSteps(route),
            Divider(
              height: 14,
              color: const Color(0xFF1C4F7A).withValues(alpha: 0.22),
            ),
            Row(
              children: [
                Expanded(
                  child: _MetricCell(
                    icon: Icons.schedule,
                    value: route.totalTravelMinutes == null
                        ? '—'
                        : '${route.totalTravelMinutes} хв',
                    label: 'Час',
                  ),
                ),
                Expanded(
                  child: _MetricCell(
                    icon: Icons.route,
                    value: route.totalDistanceMeters == null
                        ? '—'
                        : '${route.totalDistanceMeters} м',
                    label: 'Довжина',
                  ),
                ),
                Expanded(
                  child: _MetricCell(
                    icon: Icons.payments_outlined,
                    value: route.price == null
                        ? '—'
                        : '${route.price!.toStringAsFixed(route.price! % 1 == 0 ? 0 : 1)} грн',
                    label: 'Вартість',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: onPrimaryAction,
                    icon: const Icon(Icons.map),
                    label: Text(primaryActionLabel),
                  ),
                ),
                if (onSecondaryAction != null &&
                    secondaryActionLabel != null &&
                    secondaryActionIcon != null) ...[
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton.tonalIcon(
                      onPressed: onSecondaryAction,
                      icon: Icon(secondaryActionIcon),
                      label: Text(secondaryActionLabel!),
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  static List<Widget> _buildSteps(RouteResult result) {
    if (result.steps.isNotEmpty) {
      return result.steps
          .map(
            (step) => _StepRow(
              icon: _stepIcon(step.type),
              text: _stepLabel(step),
            ),
          )
          .toList(growable: false);
    }
    final widgets = <Widget>[
      _StepRow(icon: Icons.trip_origin, text: result.startName),
    ];
    for (final segment in result.previewSegments) {
      widgets.add(
        _StepRow(
          icon: _segmentIcon(segment.type),
          text: _segmentLabel(segment),
        ),
      );
    }
    widgets.add(
      _StepRow(icon: Icons.location_on_outlined, text: result.endName),
    );
    return widgets;
  }

  static IconData _stepIcon(RouteResultStepType type) {
    return switch (type) {
      RouteResultStepType.point => Icons.trip_origin,
      RouteResultStepType.walk => Icons.directions_walk,
      RouteResultStepType.zone => Icons.place_outlined,
    };
  }

  static String _stepLabel(RouteResultStep step) {
    if (step.type != RouteResultStepType.walk) {
      return step.label;
    }
    final parts = <String>[];
    if (step.meters != null) {
      parts.add('${step.meters} м');
    }
    if (step.minutes != null) {
      parts.add('${step.minutes} хв');
    }
    if (parts.isEmpty) {
      return step.label;
    }
    return '${step.label} • ${parts.join(', ')}';
  }

  static IconData _segmentIcon(RoutePreviewSegmentType type) {
    return switch (type) {
      RoutePreviewSegmentType.walk => Icons.directions_walk,
      RoutePreviewSegmentType.transfer => Icons.swap_horiz,
      RoutePreviewSegmentType.ride => Icons.directions_bus,
    };
  }

  static String _segmentLabel(RoutePreviewSegment segment) {
    if (segment.meters != null) {
      return '${segment.label} • ${segment.meters} м';
    }
    return segment.label;
  }
}

class LegacyRouteBadgeData {
  const LegacyRouteBadgeData({
    required this.icon,
    required this.label,
  });

  final IconData icon;
  final String label;
}

class _HeaderBadge extends StatelessWidget {
  const _HeaderBadge({
    required this.icon,
    required this.label,
  });

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: const Color(0xFF17324D)),
        const SizedBox(width: 6),
        Text(
          label,
          style: const TextStyle(
            color: Color(0xFF17324D),
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(width: 8),
      ],
    );
  }
}

class _StepRow extends StatelessWidget {
  const _StepRow({
    required this.icon,
    required this.text,
  });

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          SizedBox(
            width: 22,
            child: Icon(icon, size: 17, color: const Color(0xFF1C4F7A)),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(fontSize: 13, height: 1.2),
            ),
          ),
        ],
      ),
    );
  }
}

class _MetricCell extends StatelessWidget {
  const _MetricCell({
    required this.icon,
    required this.value,
    required this.label,
  });

  final IconData icon;
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: const Color(0xFF1C4F7A)),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  value,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: Colors.black.withValues(alpha: 0.56),
            ),
          ),
        ],
      ),
    );
  }
}
