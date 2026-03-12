import 'package:flutter_dozor_city/core/domain/entities/search_params.dart';
import 'package:flutter_dozor_city/core/map/app_map_camera.dart';

class BuildPreviewCameraUseCase {
  const BuildPreviewCameraUseCase();

  AppMapCamera call(SearchParams params) {
    final centerLat = (params.start.lat + params.end.lat) / 2;
    final centerLng = (params.start.lng + params.end.lng) / 2;
    final latDelta = (params.start.lat - params.end.lat).abs();
    final lngDelta = (params.start.lng - params.end.lng).abs();
    final maxDelta = latDelta > lngDelta ? latDelta : lngDelta;
    final zoom = maxDelta < 0.03
        ? 14.0
        : maxDelta < 0.08
            ? 12.8
            : 11.4;
    return AppMapCamera(
      centerLat: centerLat,
      centerLng: centerLng,
      zoom: zoom,
    );
  }
}
