import 'package:flutter_dozor_city/core/data/models/app_lat_lng_model.dart';
import 'package:flutter_dozor_city/core/data/models/json_route_line_model.dart';
import 'package:flutter_dozor_city/core/domain/entities/route_preview_segment.dart';
import 'package:flutter_dozor_city/core/domain/entities/route_result.dart';
import 'package:flutter_dozor_city/core/domain/entities/route_result_step.dart';

class JsonRouteResultModel {
  const JsonRouteResultModel({
    required this.realStartName,
    required this.realEndName,
    required this.realStart,
    required this.realEnd,
    required this.distanceStart,
    required this.distanceEnd,
    required this.totalDistanceMeters,
    required this.totalTravelMinutes,
    required this.price,
    required this.transferRoutesIds,
    required this.previewGeometry,
    required this.previewSegments,
    this.routeSteps = const [],
    required this.stored,
  });

  final String realStartName;
  final String realEndName;
  final AppLatLngModel? realStart;
  final AppLatLngModel? realEnd;
  final int distanceStart;
  final int distanceEnd;
  final int? totalDistanceMeters;
  final int? totalTravelMinutes;
  final double? price;
  final List<int> transferRoutesIds;
  final List<AppLatLngModel> previewGeometry;
  final List<RoutePreviewSegment> previewSegments;
  final List<RouteResultStep> routeSteps;
  final bool stored;

  factory JsonRouteResultModel.fromJson(Map<String, dynamic> json) {
    final transfers = (json['trs'] as List?) ?? (json['transferRoutesIds'] as List?) ?? const [];
    final lineJson = (json['line'] as Map?)?.cast<String, dynamic>() ??
        (json['routeLine'] as Map?)?.cast<String, dynamic>() ??
        (json['ln'] as Map?)?.cast<String, dynamic>();
    final directPoints = (json['pts'] as List?) ?? (json['points'] as List?);
    final distanceStart = (json['dS'] as num? ?? 0).toInt();
    final distanceEnd = (json['dE'] as num? ?? 0).toInt();
    return JsonRouteResultModel(
      realStartName: json['realStartName'] as String? ?? '',
      realEndName: json['realEndName'] as String? ?? '',
      realStart: json['realStart'] is Map
          ? AppLatLngModel.fromJson((json['realStart'] as Map).cast<String, dynamic>())
          : null,
      realEnd: json['realEnd'] is Map
          ? AppLatLngModel.fromJson((json['realEnd'] as Map).cast<String, dynamic>())
          : null,
      distanceStart: distanceStart,
      distanceEnd: distanceEnd,
      totalDistanceMeters:
          (json['d'] as num?)?.round() ??
          (json['distance'] as num?)?.round(),
      totalTravelMinutes:
          (json['time'] as num?)?.round() ??
          (json['tm'] as num?)?.round() ??
          (json['minutes'] as num?)?.round(),
      price: (json['price'] as num?)?.toDouble() ??
          (json['prc'] as num?)?.toDouble(),
      transferRoutesIds: transfers.map((item) => (item as num).toInt()).toList(growable: false),
      previewGeometry: lineJson != null
          ? JsonRouteLineModel.fromJson(lineJson).points
          : (directPoints ?? const [])
              .whereType<Map>()
              .map((item) => AppLatLngModel.fromJson(item.cast<String, dynamic>()))
              .toList(growable: false),
      previewSegments: _readSegments(
        raw: json,
        distanceStart: distanceStart,
        distanceEnd: distanceEnd,
        transferRoutesIds: transfers.map((item) => (item as num).toInt()).toList(growable: false),
      ),
      routeSteps: _readRouteSteps(raw: json),
      stored: (json['st'] as bool?) ?? false,
    );
  }

  RouteResult toEntity({required String id, required String title}) {
    return RouteResult(
      id: id,
      title: title,
      startName: realStartName,
      endName: realEndName,
      walkToStartMeters: distanceStart,
      walkToEndMeters: distanceEnd,
      transferSummary:
          transferRoutesIds.isEmpty ? 'Без пересадок' : '${transferRoutesIds.length} пересадка',
      totalDistanceMeters: totalDistanceMeters,
      totalTravelMinutes: totalTravelMinutes,
      price: price,
      realStartPoint: realStart?.toEntity(),
      realEndPoint: realEnd?.toEntity(),
      previewGeometry: previewGeometry
          .map((point) => point.toEntity())
          .toList(growable: false),
      previewSegments: previewSegments,
      steps: routeSteps,
      isStored: stored,
    );
  }

  static List<RouteResultStep> _readRouteSteps({
    required Map<String, dynamic> raw,
  }) {
    final realStartName = (raw['realStartName'] as String? ?? '').trim();
    final realEndName = (raw['realEndName'] as String? ?? '').trim();
    final startWalkLength = _toInt(raw['startWalkLength'] ?? raw['swl']);
    final startWalkTime = _toInt(raw['startWalkTime'] ?? raw['swt']);
    final transferWalkLength = _toInt(raw['transferWalkLength'] ?? raw['twl']);
    final transferWalkTime = _toInt(raw['transferWalkTime'] ?? raw['twt']);
    final endWalkLength = _toInt(raw['endWalkLength'] ?? raw['ewl']);
    final endWalkTime = _toInt(raw['endWalkTime'] ?? raw['ewt']);
    final startZone = _readZoneLabel(raw['startZone']);
    final transferZone0 = _readZoneLabel(raw['transferZone0']);
    final transferZone1 = _readZoneLabel(raw['transferZone1']);
    final endZone = _readZoneLabel(raw['endZone']);

    final hasTransfer = transferZone0 != null && transferZone1 != null;
    final steps = <RouteResultStep>[];
    if (realStartName.isNotEmpty) {
      steps.add(RouteResultStep.point(label: realStartName));
    }
    if (startWalkLength != null || startWalkTime != null) {
      steps.add(
        RouteResultStep.walk(
          label: 'Пішки до зупинки',
          meters: startWalkLength,
          minutes: startWalkTime,
        ),
      );
    }
    if (startZone != null) {
      steps.add(RouteResultStep.zone(label: startZone));
    }
    if (hasTransfer) {
      steps.add(RouteResultStep.zone(label: transferZone0));
      if (transferWalkLength != null || transferWalkTime != null) {
        steps.add(
          RouteResultStep.walk(
            label: 'Пішки на пересадку',
            meters: transferWalkLength,
            minutes: transferWalkTime,
          ),
        );
      }
      steps.add(RouteResultStep.zone(label: transferZone1));
    }
    if (endZone != null) {
      steps.add(RouteResultStep.zone(label: endZone));
    }
    if (endWalkLength != null || endWalkTime != null) {
      steps.add(
        RouteResultStep.walk(
          label: 'Пішки до пункту призначення',
          meters: endWalkLength,
          minutes: endWalkTime,
        ),
      );
    }
    if (realEndName.isNotEmpty) {
      steps.add(RouteResultStep.point(label: realEndName));
    }
    return steps;
  }

  static List<RoutePreviewSegment> _readSegments({
    required Map<String, dynamic> raw,
    required int distanceStart,
    required int distanceEnd,
    required List<int> transferRoutesIds,
  }) {
    final segmentsRaw = (raw['segments'] as List?) ?? (raw['sg'] as List?);
    if (segmentsRaw != null && segmentsRaw.isNotEmpty) {
      return segmentsRaw
          .whereType<Map>()
          .map((item) => _segmentFromJson(item.cast<String, dynamic>()))
          .toList(growable: false);
    }
    return _buildFallbackSegments(
      distanceStart: distanceStart,
      distanceEnd: distanceEnd,
      transferRoutesIds: transferRoutesIds,
    );
  }

  static RoutePreviewSegment _segmentFromJson(Map<String, dynamic> json) {
    final rawType = (json['type'] as String? ?? json['tp'] as String? ?? 'ride')
        .trim()
        .toLowerCase();
    final type = switch (rawType) {
      'walk' => RoutePreviewSegmentType.walk,
      'transfer' => RoutePreviewSegmentType.transfer,
      _ => RoutePreviewSegmentType.ride,
    };
    return RoutePreviewSegment(
      type: type,
      label: json['label'] as String? ??
          json['title'] as String? ??
          json['name'] as String? ??
          'Сегмент',
      meters: (json['meters'] as num?)?.toInt(),
    );
  }

  static List<RoutePreviewSegment> _buildFallbackSegments({
    required int distanceStart,
    required int distanceEnd,
    required List<int> transferRoutesIds,
  }) {
    final segments = <RoutePreviewSegment>[];
    if (distanceStart > 0) {
      segments.add(
        RoutePreviewSegment(
          type: RoutePreviewSegmentType.walk,
          label: 'Піша ділянка до зупинки',
          meters: distanceStart,
        ),
      );
    }
    if (transferRoutesIds.isEmpty) {
      segments.add(
        const RoutePreviewSegment(
          type: RoutePreviewSegmentType.ride,
          label: 'Прямий транспортний сегмент',
        ),
      );
    } else {
      for (var index = 0; index < transferRoutesIds.length; index++) {
        segments.add(
          RoutePreviewSegment(
            type: RoutePreviewSegmentType.ride,
            label: 'Маршрут ${transferRoutesIds[index]}',
          ),
        );
        if (index < transferRoutesIds.length - 1) {
          segments.add(
            const RoutePreviewSegment(
              type: RoutePreviewSegmentType.transfer,
              label: 'Пересадка',
            ),
          );
        }
      }
    }
    if (distanceEnd > 0) {
      segments.add(
        RoutePreviewSegment(
          type: RoutePreviewSegmentType.walk,
          label: 'Піша ділянка до пункту призначення',
          meters: distanceEnd,
        ),
      );
    }
    return segments;
  }

  static int? _toInt(Object? value) {
    return (value as num?)?.toInt();
  }

  static String? _readZoneLabel(Object? value) {
    if (value is! Map) {
      return null;
    }
    final names = value['nm'];
    if (names is List) {
      final second = names.length > 1 ? names[1] : null;
      final first = names.isNotEmpty ? names.first : null;
      final label = (second ?? first) as Object?;
      final text = label?.toString().trim() ?? '';
      if (text.isNotEmpty) {
        return text;
      }
    }
    final direct = (value['name'] as String? ?? '').trim();
    return direct.isEmpty ? null : direct;
  }
}
