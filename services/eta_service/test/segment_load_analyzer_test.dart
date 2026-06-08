import 'dart:io';

import 'package:eta_service/src/analysis/segment_load_analyzer.dart';
import 'package:eta_service/src/db/eta_database.dart';
import 'package:test/test.dart';

import 'helpers/sample_route_data.dart';

void main() {
  test('analyzes gps data into segment analytics rows', () {
    final dir = Directory.systemTemp.createTempSync('eta-service-analysis-');
    addTearDown(() => dir.deleteSync(recursive: true));

    final dbPath = '${dir.path}/service.db';
    final db = EtaDatabase.open(dbPath);
    addTearDown(db.close);

    db.replaceSnapshot(buildSampleSnapshot());
    db.insertGpsPositions(buildForwardSamplePositions());

    final analyzer = SegmentLoadAnalyzer();
    final result = analyzer.analyze(db);

    expect(result.routeCount, 1);
    expect(result.gpsRead, 4);
    expect(result.matchedPoints, 4);
    expect(result.segmentEvents, 2);
    expect(result.aggregatedRows, 2);

    expect(db.getSegmentEvents(routeId: sampleRouteId), hasLength(2));
    expect(db.getAggregatedSegmentStats(routeId: sampleRouteId), hasLength(2));
  });
}
