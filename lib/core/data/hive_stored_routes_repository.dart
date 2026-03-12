import 'package:flutter/foundation.dart';
import 'package:flutter_dozor_city/core/domain/entities/app_lat_lng.dart';
import 'package:flutter_dozor_city/core/domain/entities/route_preview_segment.dart';
import 'package:flutter_dozor_city/core/domain/entities/route_result.dart';
import 'package:flutter_dozor_city/core/domain/entities/route_result_step.dart';
import 'package:flutter_dozor_city/core/domain/repositories/stored_routes_repository.dart';
import 'package:hive/hive.dart';

class HiveStoredRoutesRepository extends ChangeNotifier
    implements StoredRoutesRepository {
  HiveStoredRoutesRepository({required Box<dynamic> box}) : _box = box;

  final Box<dynamic> _box;

  @override
  Future<bool> contains(String routeId) async => _box.containsKey(routeId);

  @override
  Future<List<RouteResult>> getStoredRoutes() async {
    return _box.values
        .map<RouteResult?>((raw) => _readRoute(raw))
        .whereType<RouteResult>()
        .toList(growable: false);
  }

  @override
  Future<void> remove(String routeId) async {
    await _box.delete(routeId);
    notifyListeners();
  }

  @override
  Future<void> save(RouteResult route) async {
    await _box.put(route.id, <String, dynamic>{
      'id': route.id,
      'title': route.title,
      'startName': route.startName,
      'endName': route.endName,
      'walkToStartMeters': route.walkToStartMeters,
      'walkToEndMeters': route.walkToEndMeters,
      'transferSummary': route.transferSummary,
      'totalDistanceMeters': route.totalDistanceMeters,
      'totalTravelMinutes': route.totalTravelMinutes,
      'price': route.price,
      'realStartPoint': route.realStartPoint == null
          ? null
          : <String, dynamic>{
              'lat': route.realStartPoint!.lat,
              'lng': route.realStartPoint!.lng,
            },
      'realEndPoint': route.realEndPoint == null
          ? null
          : <String, dynamic>{
              'lat': route.realEndPoint!.lat,
              'lng': route.realEndPoint!.lng,
            },
      'previewGeometry': route.previewGeometry
          .map(
            (point) => <String, dynamic>{
              'lat': point.lat,
              'lng': point.lng,
            },
          )
          .toList(growable: false),
      'previewSegments': route.previewSegments
          .map(
            (segment) => <String, dynamic>{
              'type': segment.type.name,
              'label': segment.label,
              'meters': segment.meters,
            },
          )
          .toList(growable: false),
      'steps': route.steps
          .map(
            (step) => <String, dynamic>{
              'type': step.type.name,
              'label': step.label,
              'meters': step.meters,
              'minutes': step.minutes,
            },
          )
          .toList(growable: false),
      'isStored': true,
    });
    notifyListeners();
  }

  RouteResult? _readRoute(dynamic raw) {
    if (raw is! Map) {
      return null;
    }
    return RouteResult(
      id: raw['id'] as String,
      title: raw['title'] as String,
      startName: raw['startName'] as String,
      endName: raw['endName'] as String,
      walkToStartMeters: raw['walkToStartMeters'] as int,
      walkToEndMeters: raw['walkToEndMeters'] as int,
      transferSummary: raw['transferSummary'] as String,
      totalDistanceMeters: (raw['totalDistanceMeters'] as num?)?.toInt(),
      totalTravelMinutes: (raw['totalTravelMinutes'] as num?)?.toInt(),
      price: (raw['price'] as num?)?.toDouble(),
      realStartPoint: raw['realStartPoint'] is Map
          ? AppLatLng(
              lat: ((raw['realStartPoint'] as Map)['lat'] as num).toDouble(),
              lng: ((raw['realStartPoint'] as Map)['lng'] as num).toDouble(),
            )
          : null,
      realEndPoint: raw['realEndPoint'] is Map
          ? AppLatLng(
              lat: ((raw['realEndPoint'] as Map)['lat'] as num).toDouble(),
              lng: ((raw['realEndPoint'] as Map)['lng'] as num).toDouble(),
            )
          : null,
      previewGeometry: ((raw['previewGeometry'] as List?) ?? const [])
          .whereType<Map>()
          .map(
            (point) => AppLatLng(
              lat: (point['lat'] as num).toDouble(),
              lng: (point['lng'] as num).toDouble(),
            ),
          )
          .toList(growable: false),
      previewSegments: ((raw['previewSegments'] as List?) ?? const [])
          .whereType<Map>()
          .map(
            (segment) => RoutePreviewSegment(
              type: switch ((segment['type'] as String? ?? 'ride').trim().toLowerCase()) {
                'walk' => RoutePreviewSegmentType.walk,
                'transfer' => RoutePreviewSegmentType.transfer,
                _ => RoutePreviewSegmentType.ride,
              },
              label: segment['label'] as String? ?? 'Сегмент',
              meters: (segment['meters'] as num?)?.toInt(),
            ),
          )
          .toList(growable: false),
      steps: ((raw['steps'] as List?) ?? const [])
          .whereType<Map>()
          .map(
            (step) => RouteResultStep(
              type: switch ((step['type'] as String? ?? 'point').trim().toLowerCase()) {
                'walk' => RouteResultStepType.walk,
                'zone' => RouteResultStepType.zone,
                _ => RouteResultStepType.point,
              },
              label: step['label'] as String? ?? '',
              meters: (step['meters'] as num?)?.toInt(),
              minutes: (step['minutes'] as num?)?.toInt(),
            ),
          )
          .toList(growable: false),
      isStored: (raw['isStored'] as bool?) ?? true,
    );
  }
}
