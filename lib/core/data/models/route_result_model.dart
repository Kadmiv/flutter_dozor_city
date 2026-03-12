import 'package:flutter_dozor_city/core/data/models/app_lat_lng_model.dart';
import 'package:flutter_dozor_city/core/domain/entities/route_preview_segment.dart';
import 'package:flutter_dozor_city/core/domain/entities/route_result.dart';
import 'package:flutter_dozor_city/core/domain/entities/route_result_step.dart';

class RouteResultModel {
  const RouteResultModel({
    required this.id,
    required this.title,
    required this.startName,
    required this.endName,
    required this.walkToStartMeters,
    required this.walkToEndMeters,
    required this.transferSummary,
    required this.totalDistanceMeters,
    required this.totalTravelMinutes,
    required this.price,
    required this.realStartPoint,
    required this.realEndPoint,
    required this.previewGeometry,
    required this.previewSegments,
    required this.steps,
  });

  final String id;
  final String title;
  final String startName;
  final String endName;
  final int walkToStartMeters;
  final int walkToEndMeters;
  final String transferSummary;
  final int? totalDistanceMeters;
  final int? totalTravelMinutes;
  final double? price;
  final AppLatLngModel? realStartPoint;
  final AppLatLngModel? realEndPoint;
  final List<AppLatLngModel> previewGeometry;
  final List<RoutePreviewSegment> previewSegments;
  final List<RouteResultStep> steps;

  factory RouteResultModel.fromJson(Map<String, dynamic> json) {
    return RouteResultModel(
      id: '${json['id'] ?? json['routeId'] ?? ''}',
      title: json['title'] as String? ?? json['name'] as String? ?? '',
      startName: json['startName'] as String? ?? json['realStartName'] as String? ?? '',
      endName: json['endName'] as String? ?? json['realEndName'] as String? ?? '',
      walkToStartMeters: (json['walkToStartMeters'] as num? ?? json['dS'] as num? ?? 0)
          .toInt(),
      walkToEndMeters: (json['walkToEndMeters'] as num? ?? json['dE'] as num? ?? 0)
          .toInt(),
      transferSummary:
          json['transferSummary'] as String? ?? 'Без пересадок',
      totalDistanceMeters:
          (json['totalDistanceMeters'] as num?)?.round() ??
          (json['d'] as num?)?.round(),
      totalTravelMinutes:
          (json['totalTravelMinutes'] as num?)?.round() ??
          (json['time'] as num?)?.round() ??
          (json['tm'] as num?)?.round(),
      price: (json['price'] as num?)?.toDouble(),
      realStartPoint: json['realStartPoint'] is Map
          ? AppLatLngModel.fromJson((json['realStartPoint'] as Map).cast<String, dynamic>())
          : null,
      realEndPoint: json['realEndPoint'] is Map
          ? AppLatLngModel.fromJson((json['realEndPoint'] as Map).cast<String, dynamic>())
          : null,
      previewGeometry: ((json['previewGeometry'] as List?) ?? const [])
          .whereType<Map>()
          .map((item) => AppLatLngModel.fromJson(item.cast<String, dynamic>()))
          .toList(growable: false),
      previewSegments: ((json['previewSegments'] as List?) ?? const [])
          .whereType<Map>()
          .map(
            (item) => RoutePreviewSegment(
              type: switch ((item['type'] as String? ?? 'ride').trim().toLowerCase()) {
                'walk' => RoutePreviewSegmentType.walk,
                'transfer' => RoutePreviewSegmentType.transfer,
                _ => RoutePreviewSegmentType.ride,
              },
              label: item['label'] as String? ?? 'Сегмент',
              meters: (item['meters'] as num?)?.toInt(),
            ),
          )
          .toList(growable: false),
      steps: ((json['steps'] as List?) ?? const [])
          .whereType<Map>()
          .map(
            (item) => RouteResultStep(
              type: switch ((item['type'] as String? ?? 'point').trim().toLowerCase()) {
                'walk' => RouteResultStepType.walk,
                'zone' => RouteResultStepType.zone,
                _ => RouteResultStepType.point,
              },
              label: item['label'] as String? ?? '',
              meters: (item['meters'] as num?)?.toInt(),
              minutes: (item['minutes'] as num?)?.toInt(),
            ),
          )
          .toList(growable: false),
    );
  }

  RouteResult toEntity() {
    return RouteResult(
      id: id,
      title: title,
      startName: startName,
      endName: endName,
      walkToStartMeters: walkToStartMeters,
      walkToEndMeters: walkToEndMeters,
      transferSummary: transferSummary,
      totalDistanceMeters: totalDistanceMeters,
      totalTravelMinutes: totalTravelMinutes,
      price: price,
      realStartPoint: realStartPoint?.toEntity(),
      realEndPoint: realEndPoint?.toEntity(),
      previewGeometry: previewGeometry
          .map((point) => point.toEntity())
          .toList(growable: false),
      previewSegments: previewSegments,
      steps: steps,
    );
  }
}
