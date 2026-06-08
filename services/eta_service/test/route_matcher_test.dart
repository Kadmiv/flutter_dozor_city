import 'package:eta_service/src/analysis/route_matcher.dart';
import 'package:test/test.dart';

import 'helpers/sample_route_data.dart';

void main() {
  test('projects gps point onto a route segment', () {
    final matcher = RouteMatcher();
    final match = matcher.match(
      buildSampleRouteTrack(),
      buildForwardSamplePositions().first,
    );

    expect(match, isNotNull);
    expect(match!.segmentId, '$sampleRouteId:$sampleStop1Id:$sampleStop2Id');
    expect(match.segmentIndex, 0);
    expect(match.distanceToRouteMeters, lessThan(120));
  });

  test('ignores far away gps points', () {
    final matcher = RouteMatcher();
    final match = matcher.match(
      buildSampleRouteTrack(),
      buildFarAwayPosition(),
    );

    expect(match, isNull);
  });
}
