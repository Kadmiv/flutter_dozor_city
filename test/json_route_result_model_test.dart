import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_dozor_city/core/data/models/json_route_result_model.dart';
import 'package:flutter_dozor_city/core/domain/entities/route_preview_segment.dart';
import 'package:flutter_dozor_city/core/domain/entities/route_result_step.dart';

void main() {
  group('JsonRouteResultModel', () {
    test('parses documented search payload shape', () {
      final model = JsonRouteResultModel.fromJson({
        'realStartName': 'Майдан Соборний',
        'realEndName': 'Автовокзал',
        'realStart': {
          'lat': 50.254,
          'lng': 28.658,
        },
        'realEnd': {
          'lat': 50.271,
          'lng': 28.676,
        },
        'dS': 120,
        'dE': 180,
        'd': 5400,
        'time': 19,
        'price': 14,
        'trs': [7, 12],
        'pts': [
          {
            'lat': 50.254,
            'lng': 28.658,
          },
          {
            'lat': 50.262,
            'lng': 28.664,
          },
          {
            'lat': 50.271,
            'lng': 28.676,
          },
        ],
        'st': true,
      });

      final entity = model.toEntity(id: 'search-1', title: 'Маршрут з пересадкою');

      expect(entity.startName, 'Майдан Соборний');
      expect(entity.endName, 'Автовокзал');
      expect(entity.realStartPoint, isNotNull);
      expect(entity.realEndPoint, isNotNull);
      expect(entity.previewGeometry.length, 3);
      expect(entity.isStored, isTrue);
      expect(entity.totalDistanceMeters, 5400);
      expect(entity.totalTravelMinutes, 19);
      expect(entity.price, 14);
      expect(entity.previewSegments, isNotEmpty);
      expect(entity.previewSegments.first.type, RoutePreviewSegmentType.walk);
      expect(entity.previewSegments.last.type, RoutePreviewSegmentType.walk);
    });

    test('uses explicit segments when backend provides them', () {
      final model = JsonRouteResultModel.fromJson({
        'realStartName': 'Точка A',
        'realEndName': 'Точка B',
        'realStart': {
          'lat': 50.1,
          'lng': 28.1,
        },
        'realEnd': {
          'lat': 50.2,
          'lng': 28.2,
        },
        'segments': [
          {
            'type': 'walk',
            'label': 'Пішки до зупинки',
            'meters': 80,
          },
          {
            'type': 'ride',
            'label': 'Маршрут №5',
          },
          {
            'type': 'transfer',
            'label': 'Пересадка',
          },
        ],
      });

      expect(model.previewSegments.length, 3);
      expect(model.previewSegments[0].type, RoutePreviewSegmentType.walk);
      expect(model.previewSegments[0].meters, 80);
      expect(model.previewSegments[1].label, 'Маршрут №5');
      expect(model.previewSegments[2].type, RoutePreviewSegmentType.transfer);
    });

    test('builds legacy route steps from search fields', () {
      final model = JsonRouteResultModel.fromJson({
        'realStartName': 'Точка A',
        'realEndName': 'Точка B',
        'startWalkLength': 150,
        'startWalkTime': 2,
        'endWalkLength': 210,
        'endWalkTime': 3,
        'transferWalkLength': 90,
        'transferWalkTime': 1,
        'startZone': {
          'nm': ['ignored', 'Зупинка Старт'],
        },
        'transferZone0': {
          'nm': ['ignored', 'Пересадка 1'],
        },
        'transferZone1': {
          'nm': ['ignored', 'Пересадка 2'],
        },
        'endZone': {
          'nm': ['ignored', 'Зупинка Фініш'],
        },
      });

      expect(model.routeSteps.length, 9);
      expect(model.routeSteps.first, const RouteResultStep.point(label: 'Точка A'));
      expect(
        model.routeSteps[1],
        const RouteResultStep.walk(
          label: 'Пішки до зупинки',
          meters: 150,
          minutes: 2,
        ),
      );
      expect(
        model.routeSteps[2],
        const RouteResultStep.zone(label: 'Зупинка Старт'),
      );
      expect(
        model.routeSteps[3],
        const RouteResultStep.zone(label: 'Пересадка 1'),
      );
      expect(
        model.routeSteps[4],
        const RouteResultStep.walk(
          label: 'Пішки на пересадку',
          meters: 90,
          minutes: 1,
        ),
      );
      expect(
        model.routeSteps[5],
        const RouteResultStep.zone(label: 'Пересадка 2'),
      );
      expect(
        model.routeSteps[6],
        const RouteResultStep.zone(label: 'Зупинка Фініш'),
      );
      expect(
        model.routeSteps[7],
        const RouteResultStep.walk(
          label: 'Пішки до пункту призначення',
          meters: 210,
          minutes: 3,
        ),
      );
      expect(model.routeSteps.last, const RouteResultStep.point(label: 'Точка B'));
    });
  });
}
