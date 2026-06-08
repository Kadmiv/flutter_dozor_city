import 'dart:convert';

import 'package:eta_service/src/db/eta_database.dart';
import 'package:eta_service/src/server/app.dart';
import 'package:shelf/shelf_io.dart' as io;
import 'package:test/test.dart';
import 'package:http/http.dart' as http;

void main() {
  test('serves health and gps endpoints', () async {
    final db = EtaDatabase.open(':memory:');
    addTearDown(db.close);

    final server = await io.serve(EtaHttpApp(db).build(), '127.0.0.1', 0);
    addTearDown(server.close);

    final base = Uri.parse('http://127.0.0.1:${server.port}');
    final index = await http.get(base);
    expect(index.statusCode, 200);
    expect(jsonDecode(index.body)['service'], 'eta_service');

    final health = await http.get(base.resolve('/health'));
    expect(health.statusCode, 200);

    final post = await http.post(
      base.resolve('/gps'),
      headers: const {'content-type': 'application/json'},
      body: jsonEncode({
        'vehicleId': 'v1',
        'routeId': 'r1',
        'timestampMs': 1,
        'lat': 1.0,
        'lon': 2.0,
        'speed': 0,
        'azimuth': 0,
        'govNumber': 'GN',
      }),
    );
    expect(post.statusCode, 200);

    final badPost = await http.post(
      base.resolve('/gps'),
      headers: const {'content-type': 'application/json'},
      body: jsonEncode({'vehicleId': 'v1'}),
    );
    expect(badPost.statusCode, 400);

    final batch = await http.post(
      base.resolve('/gps/batch'),
      headers: const {'content-type': 'application/json'},
      body: jsonEncode([
        {
          'vehicleId': 'v2',
          'routeId': 'r1',
          'timestampMs': 2,
          'lat': 3.0,
          'lon': 4.0,
          'speed': 0,
          'azimuth': 0,
          'govNumber': 'GN2',
        },
        {'vehicleId': 'broken'},
      ]),
    );
    expect(batch.statusCode, 200);
    expect(jsonDecode(batch.body)['received'], 1);

    final list = await http.get(base.resolve('/gps?vehicleId=v1&limit=10'));
    expect(list.statusCode, 200);
    final items = jsonDecode(list.body)['items'] as List<dynamic>;
    expect(items, hasLength(1));
    expect(
      items.single.keys,
      containsAll(['vehicleId', 'routeId', 'timestampMs', 'lat', 'lon']),
    );
    expect(items.single.containsKey('speed'), isFalse);
    expect(items.single.containsKey('govNumber'), isFalse);
  });
}
