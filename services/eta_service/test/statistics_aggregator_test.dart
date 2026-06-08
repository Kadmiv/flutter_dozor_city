import 'package:eta_service/src/analysis/statistics_aggregator.dart';
import 'package:eta_service/src/domain/models.dart';
import 'package:test/test.dart';

void main() {
  test('groups events into 30 minute buckets by day type', () {
    final aggregator = StatisticsAggregator();
    final monday1 = DateTime(2026, 6, 8, 8, 15).millisecondsSinceEpoch;
    final monday2 = DateTime(2026, 6, 8, 8, 25).millisecondsSinceEpoch;
    final saturday = DateTime(2026, 6, 6, 8, 45).millisecondsSinceEpoch;
    final sunday = DateTime(2026, 6, 7, 9, 5).millisecondsSinceEpoch;
    final stats = aggregator.aggregate([
      SegmentEventRecord(
        vehicleId: 'v1',
        segmentId: 'r1:s1:s2',
        startedAtMs: monday1,
        finishedAtMs: monday1 + 60000,
        durationSec: 60,
      ),
      SegmentEventRecord(
        vehicleId: 'v2',
        segmentId: 'r1:s1:s2',
        startedAtMs: monday2,
        finishedAtMs: monday2 + 120000,
        durationSec: 120,
      ),
      SegmentEventRecord(
        vehicleId: 'v3',
        segmentId: 'r1:s1:s2',
        startedAtMs: saturday,
        finishedAtMs: saturday + 30000,
        durationSec: 30,
      ),
      SegmentEventRecord(
        vehicleId: 'v4',
        segmentId: 'r1:s2:s3',
        startedAtMs: sunday,
        finishedAtMs: sunday + 45000,
        durationSec: 45,
      ),
    ]);

    expect(stats, hasLength(3));
    final weekdayBucket = stats.firstWhere(
      (row) => row.dayType == 'weekday' && row.segmentId == 'r1:s1:s2',
    );
    expect(weekdayBucket.bucketStartMin, 480);
    expect(weekdayBucket.bucketEndMin, 510);
    expect(weekdayBucket.sampleCount, 2);
    expect(weekdayBucket.averageDurationSec, closeTo(90, 0.001));
  });
}
