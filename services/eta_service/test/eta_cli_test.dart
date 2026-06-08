import 'dart:io';

import 'package:eta_service/src/cli/eta_cli.dart';
import 'package:eta_service/src/db/eta_database.dart';
import 'package:eta_service/src/domain/models.dart';
import 'package:test/test.dart';

void main() {
  test('migrate creates the database file', () async {
    final dir = Directory.systemTemp.createTempSync('eta-service-');
    addTearDown(() => dir.deleteSync(recursive: true));

    final dbPath = '${dir.path}/service.db';
    await runEtaCli(['migrate', '--db-path=$dbPath']);

    expect(File(dbPath).existsSync(), isTrue);
  });

  test('export-json writes a snapshot file', () async {
    final dir = Directory.systemTemp.createTempSync('eta-service-export-');
    addTearDown(() => dir.deleteSync(recursive: true));

    final dbPath = '${dir.path}/service.db';
    final outPath = '${dir.path}/snapshot.json';
    final db = EtaDatabase.open(dbPath);
    addTearDown(db.close);
    db.replaceSnapshot(
      const BatumiSnapshot(
        routes: [
          RouteRecord(
            id: 'r1',
            shortName: '1',
            title: 'Route 1',
            transportType: 0,
            sortOrder: 10,
            isCircle: false,
          ),
        ],
        stops: const [],
        routeStops: const [],
        routePolylines: const [],
      ),
    );

    await runEtaCli(['export-json', '--db-path=$dbPath', '--out=$outPath']);

    final file = File(outPath);
    expect(file.existsSync(), isTrue);
    final contents = file.readAsStringSync();
    expect(contents, contains('"routes"'));
    expect(contents, isNot(contains('"gps_positions"')));
  });
}
