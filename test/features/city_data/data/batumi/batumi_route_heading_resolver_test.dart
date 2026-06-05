import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_dozor_city/features/city_data/data/batumi/batumi_bus_location_dto.dart';
import 'package:flutter_dozor_city/features/city_data/data/batumi/batumi_db_data_dto.dart';
import 'package:flutter_dozor_city/features/city_data/data/batumi/batumi_points_between_stations_dto.dart';
import 'package:flutter_dozor_city/features/city_data/data/batumi/batumi_route_heading_resolver.dart';

void main() {
  group('BatumiRouteHeadingResolver', () {
    test('uses route direction to calculate azimuth', () {
      final resolver = BatumiRouteHeadingResolver();
      final snapshot = BatumiDbDataDto(
        busStops: {
          's1': BatumiBusStopDto(
            id: 's1',
            nameGeoGps: 's1',
            number: 1,
            nameKa: 's1',
            nameEn: 's1',
            lat: 41.0,
            lon: 41.0,
            routeTRouteIdGeoGps: null,
            routes: {
              'r1': const BatumiBusStopRouteDto(status: 1, order: 1, times: []),
            },
          ),
          's2': BatumiBusStopDto(
            id: 's2',
            nameGeoGps: 's2',
            number: 2,
            nameKa: 's2',
            nameEn: 's2',
            lat: 41.0,
            lon: 41.01,
            routeTRouteIdGeoGps: null,
            routes: {
              'r1': const BatumiBusStopRouteDto(status: 1, order: 2, times: []),
            },
          ),
          's3': BatumiBusStopDto(
            id: 's3',
            nameGeoGps: 's3',
            number: 3,
            nameKa: 's3',
            nameEn: 's3',
            lat: 41.0,
            lon: 41.02,
            routeTRouteIdGeoGps: null,
            routes: {
              'r1': const BatumiBusStopRouteDto(status: 2, order: 3, times: []),
            },
          ),
          's4': BatumiBusStopDto(
            id: 's4',
            nameGeoGps: 's4',
            number: 4,
            nameKa: 's4',
            nameEn: 's4',
            lat: 41.0,
            lon: 41.03,
            routeTRouteIdGeoGps: null,
            routes: {
              'r1': const BatumiBusStopRouteDto(status: 2, order: 4, times: []),
            },
          ),
        },
        routeStatusInfo: const {},
        routesNames: const {},
        routeCoordinatesGrouped: const {},
      );
      final points = BatumiPointsBetweenStationsDto(
        data: {
          'r1': {
            's1': [
              const BatumiPointBetweenStationsDto(lat: 41.0, lon: 41.0),
              const BatumiPointBetweenStationsDto(lat: 41.0, lon: 41.01),
            ],
            's2': [
              const BatumiPointBetweenStationsDto(lat: 41.0, lon: 41.01),
              const BatumiPointBetweenStationsDto(lat: 41.0, lon: 41.02),
            ],
            's3': [
              const BatumiPointBetweenStationsDto(lat: 41.0, lon: 41.03),
              const BatumiPointBetweenStationsDto(lat: 41.0, lon: 41.02),
            ],
            's4': [
              const BatumiPointBetweenStationsDto(lat: 41.0, lon: 41.02),
              const BatumiPointBetweenStationsDto(lat: 41.0, lon: 41.01),
            ],
          },
        },
      );

      final eastbound = resolver.resolveAzimuth(
        routeId: 'r1',
        location: const BatumiBusLocationDto(
          lat: 41.0,
          lon: 41.005,
          status: 1,
          name: 'bus-1',
        ),
        snapshot: snapshot,
        points: points,
      );
      final westbound = resolver.resolveAzimuth(
        routeId: 'r1',
        location: const BatumiBusLocationDto(
          lat: 41.0,
          lon: 41.025,
          status: 2,
          name: 'bus-2',
        ),
        snapshot: snapshot,
        points: points,
      );

      expect(eastbound, anyOf(inInclusiveRange(80, 100), inInclusiveRange(260, 280)));
      expect(westbound, anyOf(inInclusiveRange(80, 100), inInclusiveRange(260, 280)));
      expect(eastbound, isNot(westbound));
    });

    test('falls back to full route path when status is unknown', () {
      final resolver = BatumiRouteHeadingResolver();
      final snapshot = BatumiDbDataDto(
        busStops: const {},
        routeStatusInfo: const {},
        routesNames: const {},
        routeCoordinatesGrouped: const {},
      );
      final points = BatumiPointsBetweenStationsDto(
        data: {
          'r1': {
            's1': [
              const BatumiPointBetweenStationsDto(lat: 41.0, lon: 41.0),
              const BatumiPointBetweenStationsDto(lat: 41.0, lon: 41.01),
            ],
          },
        },
      );

      final azimuth = resolver.resolveAzimuth(
        routeId: 'r1',
        location: const BatumiBusLocationDto(
          lat: 41.0,
          lon: 41.005,
          status: -1,
          name: 'bus-3',
        ),
        snapshot: snapshot,
        points: points,
      );

      expect(azimuth, inInclusiveRange(80, 100));
    });
  });
}
