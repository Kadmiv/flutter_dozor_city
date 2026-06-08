import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:flutter_dozor_city/core/domain/entities/arrival_info.dart';
import 'package:flutter_dozor_city/core/domain/entities/route_arrival.dart';
import 'package:flutter_dozor_city/features/city_data/data/datasources/local/hive_city_local_data_source.dart';

void main() {
  late Directory tempDir;
  late Box<dynamic> citiesBox;
  late Box<dynamic> routesBox;

  setUpAll(() async {
    tempDir = await Directory.systemTemp.createTemp('hive_city_local_test_');
    Hive.init(tempDir.path);
  });

  setUp(() async {
    citiesBox = await Hive.openBox<dynamic>('cities');
    routesBox = await Hive.openBox<dynamic>('routes');
  });

  tearDown(() async {
    await citiesBox.close();
    await routesBox.close();
    await Hive.deleteBoxFromDisk('cities');
    await Hive.deleteBoxFromDisk('routes');
  });

  tearDownAll(() async {
    if (tempDir.existsSync()) {
      await tempDir.delete(recursive: true);
    }
  });

  test('reads old arrival cache without routeArrivals', () async {
    final local = HiveCityLocalDataSource(
      citiesBox: citiesBox,
      routesBox: routesBox,
    );

    await routesBox.put('arrival:stop-1', <String, dynamic>{
      'zoneId': 'stop-1',
      'busMinutes': [1, 4],
      'trolleyMinutes': [7],
      'tramMinutes': [9],
    });

    final arrival = await local.getArrivalByZone('stop-1');

    expect(arrival, isNotNull);
    expect(arrival!.routeArrivals, isEmpty);
    expect(arrival.busMinutes, [1, 4]);
  });

  test('saves and restores rich route arrivals', () async {
    final local = HiveCityLocalDataSource(
      citiesBox: citiesBox,
      routesBox: routesBox,
    );
    const arrival = ArrivalInfo(
      zoneId: 'stop-1',
      busMinutes: [2, 13],
      trolleyMinutes: [],
      tramMinutes: [],
      routeArrivals: [
        RouteArrival(
          routeId: 'route-1',
          routeShortName: '10',
          busId: 'bus-1',
          busName: 'TT 683 ET',
          minute: 2,
        ),
      ],
    );

    await local.saveArrivalByZone(arrival);
    final restored = await local.getArrivalByZone('stop-1');

    expect(restored, arrival);
    expect(restored!.routeArrivals.single.busName, 'TT 683 ET');
  });
}
