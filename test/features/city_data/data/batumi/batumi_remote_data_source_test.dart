import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_dozor_city/core/network/dio_client.dart';
import 'package:flutter_dozor_city/core/network/request/app_request.dart';
import 'package:flutter_dozor_city/features/city_data/data/batumi/batumi_bus_location_dto.dart';
import 'package:flutter_dozor_city/features/city_data/data/batumi/batumi_city_catalog.dart';
import 'package:flutter_dozor_city/features/city_data/data/batumi/batumi_db_data_dto.dart';
import 'package:flutter_dozor_city/features/city_data/data/batumi/batumi_live_data_dto.dart';
import 'package:flutter_dozor_city/features/city_data/data/batumi/batumi_points_between_stations_dto.dart';
import 'package:flutter_dozor_city/features/city_data/data/datasources/remote/batumi_remote_data_source.dart';

class _FakeBatumiDioClient extends DioClient {
  _FakeBatumiDioClient({this.failLiveRoutes = const <String>{}});

  final Set<String> failLiveRoutes;

  @override
  Future<Response<dynamic>> request(AppRequest request) async {
    if (request.path == '/api/getDbData') {
      return Response<dynamic>(
        requestOptions: RequestOptions(path: request.path),
        data: _dbResponse,
      );
    }
    if (request.path == '/api/getPointsBetweenStations') {
      return Response<dynamic>(
        requestOptions: RequestOptions(path: request.path),
        data: _pointsResponse,
      );
    }
    if (request.path == '/api/getBusLocsOnRoute') {
      final routeId = '${request.queryParameters?['routeId'] ?? ''}';
      final response = _liveResponses[routeId];
      return Response<dynamic>(
        requestOptions: RequestOptions(path: request.path),
        data: response ?? <String, dynamic>{'data': <Map<String, dynamic>>[]},
      );
    }
    if (request.path == '/api/getLiveData') {
      final routeId = '${request.queryParameters?['routeId'] ?? ''}';
      if (failLiveRoutes.contains(routeId)) {
        throw DioException(
          requestOptions: RequestOptions(path: request.path),
          message: 'Live data failure for $routeId',
        );
      }
      final response = _liveDataResponses[routeId];
      return Response<dynamic>(
        requestOptions: RequestOptions(path: request.path),
        data: response ?? <String, dynamic>{'data': <Map<String, dynamic>>[]},
      );
    }
    throw StateError('Unexpected request: ${request.path}');
  }

  static const _dbResponse = {
    'data': {
      'busStops': {
        'stop-1': {
          'BusStopIdGeoGps': 'stop-1',
          'BusStopNameGeoGps': 'Stop 1',
          'BusStopNumber': 1,
          'BusStopNameKA': 'Stop 1 KA',
          'BusStopNameEN': 'Stop 1 EN',
          'BusStopLatitude': 41.60,
          'BusStopLongitude': 41.61,
          'RouteT_RouteIdGeoGps': null,
          'routes': {
            'route-1': {
              'Status': 1,
              'Order': 1,
              'times': ['07:00'],
            },
            'route-2': {
              'Status': 2,
              'Order': 1,
              'times': ['08:00'],
            },
          },
        },
        'stop-2': {
          'BusStopIdGeoGps': 'stop-2',
          'BusStopNameGeoGps': 'Stop 2',
          'BusStopNumber': 2,
          'BusStopNameKA': 'Stop 2 KA',
          'BusStopNameEN': 'Stop 2 EN',
          'BusStopLatitude': 41.61,
          'BusStopLongitude': 41.62,
          'RouteT_RouteIdGeoGps': null,
          'routes': {
            'route-1': {
              'Status': 1,
              'Order': 2,
              'times': ['07:10'],
            },
          },
        },
      },
      'routeStatusInfo': {
        'route-1': {
          '1': {'lowestId': 'stop-1', 'highestId': 'stop-2'},
        },
        'route-2': {
          '2': {'lowestId': 'stop-1', 'highestId': 'stop-1'},
        },
      },
      'routesNames': {
        'route-1': {
          'RouteIdGeoGps': 'route-1',
          'RouteNameGeoGps': '1',
          'RouteNameKA': '1',
          'RouteNameEN': '1',
          'RouteIsCircle': false,
          'RouteSortOrder': 10,
        },
        'route-2': {
          'RouteIdGeoGps': 'route-2',
          'RouteNameGeoGps': '2',
          'RouteNameKA': '2',
          'RouteNameEN': '2',
          'RouteIsCircle': false,
          'RouteSortOrder': 20,
        },
      },
      'routeCoordinatesGrouped': {
        'route-1': {
          '0': {'lat': 41.60, 'lon': 41.61},
          '1': {'lat': 41.605, 'lon': 41.615},
          '2': {'lat': 41.61, 'lon': 41.62},
        },
        'route-2': {
          '0': {'lat': 41.59, 'lon': 41.60},
          '1': {'lat': 41.595, 'lon': 41.605},
        },
      },
    },
  };

  static const _pointsResponse = {
    'data': {
      'route-1': {
        'stop-1': [
          [41.60, 41.61],
          [41.605, 41.615],
          [41.61, 41.62],
        ],
        'stop-2': [
          [41.61, 41.62],
          [41.615, 41.625],
        ],
      },
      'route-2': {
        'stop-1': [
          [41.59, 41.60],
          [41.595, 41.605],
        ],
      },
    },
  };

  static const Map<String, Map<String, dynamic>> _liveResponses = {
    'route-1': {
      'data': [
        {'Lat': 41.601, 'Lon': 41.611, 'Status': 1, 'Name': 'BAT-1'},
        {'Lat': 41.602, 'Lon': 41.612, 'Status': -1, 'Name': 'BAT-OFF'},
      ],
    },
    'route-2': {
      'data': [
        {'Lat': 41.591, 'Lon': 41.601, 'Status': 2, 'Name': 'BAT-2'},
      ],
    },
  };

  static const Map<String, Map<String, dynamic>> _liveDataResponses = {
    'route-1': {
      'data': {
        'arrivalTime': [
          {
            'arrival_times': {
              'first_bus': {
                'bus_id': '6724aa47d2c2645e78ae6767',
                'bus_name': 'TT 683 ET',
                'minute': 2,
              },
              'second_bus': {
                'bus_id': '6724aa47d2c2645e78ae6781',
                'bus_name': 'TT 689 ET',
                'minute': 13,
              },
            },
            'name': '1089 თბილისის მოედანი',
            'stop_id': 'stop-1',
          },
        ],
      },
    },
    'route-2': {
      'data': {
        'arrivalTime': [
          {
            'arrival_times': {
              'first_bus': {
                'bus_id': '6724aa47d2c2645e78ae6767',
                'bus_name': 'TT 683 ET',
                'minute': 1,
              },
              'second_bus': {
                'bus_id': '6724aa47d2c2645e78ae6781',
                'bus_name': 'TT 689 ET',
                'minute': 12,
              },
            },
            'name': '1089 თბილისის მოედანი',
            'stop_id': 'stop-1',
          },
        ],
      },
    },
  };
}

void main() {
  group('Batumi DTOs', () {
    test('parses Batumi db snapshot and live points', () {
      final db = BatumiDbDataDto.fromApiResponse(
        _FakeBatumiDioClient._dbResponse,
      );
      final points = BatumiPointsBetweenStationsDto.fromJson(
        _FakeBatumiDioClient._pointsResponse,
      );
      final live = BatumiBusLocationsResponseDto.fromJson(
        _FakeBatumiDioClient._liveResponses['route-1']!,
      );
      final liveData = BatumiLiveDataResponseDto.fromApiResponse(
        _FakeBatumiDioClient._liveDataResponses['route-1'],
      );

      expect(db.routesNames.length, 2);
      expect(db.busStops.length, 2);
      expect(db.routeCoordinatesGrouped['route-1']!.orderedPoints.length, 3);
      expect(points.data['route-1']!['stop-1']!.length, 3);
      expect(
        live.locations.map((location) => location.name),
        containsAll(['BAT-1', 'BAT-OFF']),
      );
      expect(liveData.arrivalTimes.single.stopId, 'stop-1');
      expect(liveData.arrivalTimes.single.arrivalTimes, hasLength(2));
    });

    test('handles missing arrivalTime list', () {
      final liveData = BatumiLiveDataResponseDto.fromApiResponse(const {
        'data': {},
      });

      expect(liveData.arrivalTimes, isEmpty);
    });
  });

  group('BatumiRemoteDataSource', () {
    test('builds routes, vehicles, and city data for Batumi', () async {
      final remote = BatumiRemoteDataSource(_FakeBatumiDioClient());

      final cities = await remote.getCities();
      expect(cities.single.id, BatumiCityCatalog.cityId);

      final routes = await remote.getRoutesByType(
        cityId: BatumiCityCatalog.cityId,
        transportType: 0,
      );
      expect(routes, hasLength(2));
      expect(routes.first.shortName, '1');
      expect(routes.first.polylineSegments, isNotEmpty);
      expect(routes.first.lineColorValue, isNot(0));

      final routesByOtherType = await remote.getRoutesByType(
        cityId: BatumiCityCatalog.cityId,
        transportType: 1,
      );
      expect(routesByOtherType, isEmpty);

      final zones = await remote.getRouteZones('route-1');
      expect(zones, hasLength(2));
      expect(zones.first.name, 'Stop 1 EN');

      final vehicles = await remote.getCityVehicles(
        BatumiCityCatalog.cityId,
        routeIds: const ['route-1'],
      );
      expect(vehicles, hasLength(1));
      expect(vehicles.single.routeId, 'route-1');
      expect(vehicles.single.govNumber, 'BAT-1');
      expect(vehicles.single.transportType, 0);
      expect(
        vehicles.any((vehicle) => vehicle.govNumber == 'BAT-OFF'),
        isFalse,
      );

      final arrival = await remote.getArrivalByZone(
        cityId: BatumiCityCatalog.cityId,
        zoneId: 'stop-1',
      );
      expect(arrival.zoneId, 'stop-1');
      expect(arrival.busMinutes, [1, 2, 12, 13]);
      expect(arrival.routeArrivals, hasLength(4));
      expect(arrival.routeArrivals.first.minute, 1);
      expect(arrival.routeArrivals.first.busName, 'TT 683 ET');
    });

    test('keeps successful route arrivals when one route fails', () async {
      final remote = BatumiRemoteDataSource(
        _FakeBatumiDioClient(failLiveRoutes: const {'route-2'}),
      );

      final arrival = await remote.getArrivalByZone(
        cityId: BatumiCityCatalog.cityId,
        zoneId: 'stop-1',
      );

      expect(arrival.routeArrivals, hasLength(2));
      expect(arrival.busMinutes, [2, 13]);
    });
  });
}
