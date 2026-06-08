import 'dart:convert';

import 'package:eta_service/src/batumi/batumi_api_client.dart';
import 'package:http/http.dart' as http;
import 'package:test/test.dart';

class _FakeClient extends http.BaseClient {
  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    final body = switch (request.url.path) {
      '/api/getDbData' => jsonEncode({
        'data': {
          'busStops': {
            'stop-1': {
              'BusStopIdGeoGps': 'stop-1',
              'BusStopNameKA': 'Stop 1',
              'BusStopNameEN': 'Stop 1 EN',
              'BusStopLatitude': 41.6,
              'BusStopLongitude': 41.61,
              'BusStopNumber': 1,
              'routes': {
                'route-1': {
                  'Status': 1,
                  'Order': 1,
                  'times': ['07:00'],
                },
              },
            },
          },
          'routesNames': {
            'route-1': {
              'RouteNameEN': '1',
              'RouteNameKA': '1',
              'RouteSortOrder': 10,
              'RouteIsCircle': false,
            },
          },
          'routeCoordinatesGrouped': {
            'route-1': {
              '0': {'lat': 41.6, 'lon': 41.61},
              '1': {'lat': 41.61, 'lon': 41.62},
            },
          },
        },
      }),
      '/api/getPointsBetweenStations' => jsonEncode({'data': {}}),
      '/api/getBusLocsOnRoute' => jsonEncode({
        'data': [
          {'Lat': 41.601, 'Lon': 41.611, 'Status': 1, 'Name': 'BAT-1'},
          {'Lat': 41.602, 'Lon': 41.612, 'Status': -1, 'Name': 'BAT-OFF'},
        ],
      }),
      _ => throw StateError('Unexpected path: ${request.url.path}'),
    };
    return http.StreamedResponse(
      Stream.value(utf8.encode(body)),
      200,
      request: request,
      headers: const {'content-type': 'application/json'},
    );
  }
}

void main() {
  test('loads batumi snapshot and live positions', () async {
    final client = BatumiApiClient(
      baseUrl: 'https://thetamaps.site:54321',
      client: _FakeClient(),
    );

    final snapshot = await client.loadSnapshot();
    expect(snapshot.routes, hasLength(1));
    expect(snapshot.stops, hasLength(1));

    final positions = await client.pollRoute('route-1');
    expect(positions, hasLength(1));
    expect(positions.single.vehicleId, 'route-1:BAT-1');
  });
}
