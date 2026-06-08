import 'package:eta_service/src/analysis/segment_analyzer.dart';
import 'package:test/test.dart';

import 'helpers/sample_route_data.dart';

void main() {
  test('creates segment events for forward movement', () {
    final analyzer = SegmentAnalyzer();
    final events = analyzer.buildEvents(
      buildSampleRouteTrack(),
      buildForwardSamplePositions(),
    );

    expect(events, hasLength(2));
    expect(
      events.first.segmentId,
      '$sampleRouteId:$sampleStop1Id:$sampleStop2Id',
    );
    expect(
      events.last.segmentId,
      '$sampleRouteId:$sampleStop2Id:$sampleStop3Id',
    );
    expect(events.first.durationSec, greaterThan(0));
  });

  test('skips reverse jumps that would create garbage events', () {
    final analyzer = SegmentAnalyzer();
    final events = analyzer.buildEvents(
      buildSampleRouteTrack(),
      buildReverseJumpPositions(),
    );

    expect(events, hasLength(1));
    expect(events.every((event) => event.durationSec > 0), isTrue);
  });
}
