import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_dozor_city/core/data/mappers/search_route_result_mapper.dart';
import 'package:flutter_dozor_city/core/data/models/app_lat_lng_model.dart';
import 'package:flutter_dozor_city/core/data/models/json_route_result_model.dart';
import 'package:flutter_dozor_city/core/domain/entities/route_preview_segment.dart';

void main() {
  group('SearchRouteResultMapper', () {
    const mapper = SearchRouteResultMapper();

    test('maps direct route with direct title', () {
      const model = JsonRouteResultModel(
        realStartName: 'Старт',
        realEndName: 'Фініш',
        realStart: AppLatLngModel(lat: 50.1, lng: 28.1),
        realEnd: AppLatLngModel(lat: 50.2, lng: 28.2),
        distanceStart: 120,
        distanceEnd: 80,
        totalDistanceMeters: 4200,
        totalTravelMinutes: 17,
        price: 12,
        transferRoutesIds: [],
        previewGeometry: [],
        previewSegments: [
          RoutePreviewSegment(
            type: RoutePreviewSegmentType.ride,
            label: 'Прямий транспортний сегмент',
          ),
        ],
        stored: false,
      );

      final result = mapper.map(model: model, index: 3);

      expect(result.id, 'search-3');
      expect(result.title, 'Прямий маршрут');
      expect(result.startName, 'Старт');
      expect(result.endName, 'Фініш');
      expect(result.totalDistanceMeters, 4200);
      expect(result.totalTravelMinutes, 17);
      expect(result.price, 12);
    });

    test('maps transfer route with transfer title', () {
      const model = JsonRouteResultModel(
        realStartName: 'Старт',
        realEndName: 'Фініш',
        realStart: null,
        realEnd: null,
        distanceStart: 0,
        distanceEnd: 0,
        totalDistanceMeters: null,
        totalTravelMinutes: null,
        price: null,
        transferRoutesIds: [7, 12],
        previewGeometry: [],
        previewSegments: [],
        stored: true,
      );

      final result = mapper.map(model: model, index: 1);

      expect(result.id, 'search-1');
      expect(result.title, 'Маршрут з пересадкою');
      expect(result.isStored, isTrue);
    });
  });
}
