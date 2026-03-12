import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_dozor_city/core/domain/entities/route_preview_segment.dart';
import 'package:flutter_dozor_city/features/route_preview/presentation/bloc/route_preview_cubit.dart';

class RoutePreviewPanel extends StatelessWidget {
  const RoutePreviewPanel({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<RoutePreviewCubit, RoutePreviewState>(
      builder: (context, state) {
        final previewRoute = state.route;
        if (previewRoute == null) {
          return const SizedBox.shrink();
        }
        return Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFF1C4F7A),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: Colors.white.withValues(alpha: 0.18)),
          ),
          child: Row(
            children: [
              const Icon(Icons.alt_route, color: Colors.white),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      previewRoute.title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${previewRoute.startName} -> ${previewRoute.endName}',
                      style: const TextStyle(color: Colors.white70),
                    ),
                    if (previewRoute.previewSegments.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: previewRoute.previewSegments
                            .map(
                              (segment) => Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(999),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      _segmentIcon(segment.type),
                                      color: Colors.white,
                                      size: 16,
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      _segmentLabel(segment),
                                      style: const TextStyle(
                                        color: Colors.white,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            )
                            .toList(growable: false),
                      ),
                    ],
                  ],
                ),
              ),
              IconButton(
                onPressed: () => context.read<RoutePreviewCubit>().clear(),
                icon: const Icon(Icons.close, color: Colors.white),
              ),
            ],
          ),
        );
      },
    );
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
