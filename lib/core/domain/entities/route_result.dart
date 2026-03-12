import 'package:equatable/equatable.dart';
import 'package:flutter_dozor_city/core/domain/entities/app_lat_lng.dart';
import 'package:flutter_dozor_city/core/domain/entities/route_preview_segment.dart';
import 'package:flutter_dozor_city/core/domain/entities/route_result_step.dart';

class RouteResult extends Equatable {
  const RouteResult({
    required this.id,
    required this.title,
    required this.startName,
    required this.endName,
    required this.walkToStartMeters,
    required this.walkToEndMeters,
    required this.transferSummary,
    this.totalDistanceMeters,
    this.totalTravelMinutes,
    this.price,
    this.realStartPoint,
    this.realEndPoint,
    this.previewGeometry = const [],
    this.previewSegments = const [],
    this.steps = const [],
    this.isStored = false,
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
  final AppLatLng? realStartPoint;
  final AppLatLng? realEndPoint;
  final List<AppLatLng> previewGeometry;
  final List<RoutePreviewSegment> previewSegments;
  final List<RouteResultStep> steps;
  final bool isStored;

  RouteResult copyWith({
    bool? isStored,
    int? totalDistanceMeters,
    int? totalTravelMinutes,
    double? price,
    AppLatLng? realStartPoint,
    AppLatLng? realEndPoint,
    List<AppLatLng>? previewGeometry,
    List<RoutePreviewSegment>? previewSegments,
    List<RouteResultStep>? steps,
  }) {
    return RouteResult(
      id: id,
      title: title,
      startName: startName,
      endName: endName,
      walkToStartMeters: walkToStartMeters,
      walkToEndMeters: walkToEndMeters,
      transferSummary: transferSummary,
      totalDistanceMeters: totalDistanceMeters ?? this.totalDistanceMeters,
      totalTravelMinutes: totalTravelMinutes ?? this.totalTravelMinutes,
      price: price ?? this.price,
      realStartPoint: realStartPoint ?? this.realStartPoint,
      realEndPoint: realEndPoint ?? this.realEndPoint,
      previewGeometry: previewGeometry ?? this.previewGeometry,
      previewSegments: previewSegments ?? this.previewSegments,
      steps: steps ?? this.steps,
      isStored: isStored ?? this.isStored,
    );
  }

  @override
  List<Object?> get props => [
        id,
        title,
        startName,
        endName,
        walkToStartMeters,
        walkToEndMeters,
        transferSummary,
        totalDistanceMeters,
        totalTravelMinutes,
        price,
        realStartPoint,
        realEndPoint,
        previewGeometry,
        previewSegments,
        steps,
        isStored,
      ];
}
