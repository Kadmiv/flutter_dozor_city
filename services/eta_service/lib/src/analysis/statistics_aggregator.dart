import '../domain/models.dart';

class StatisticsAggregator {
  List<AggregatedSegmentStatRecord> aggregate(List<SegmentEventRecord> events) {
    final buckets = <String, _AggregateBucket>{};
    for (final event in events) {
      final startedAt = DateTime.fromMillisecondsSinceEpoch(
        event.startedAtMs,
      ).toLocal();
      final dayType = _dayType(startedAt);
      final bucketStartMin =
          (startedAt.hour * 60 + startedAt.minute) ~/ 30 * 30;
      final bucketEndMin = bucketStartMin + 30;
      final key = '${event.segmentId}|$dayType|$bucketStartMin';
      final bucket = buckets.putIfAbsent(
        key,
        () => _AggregateBucket(
          segmentId: event.segmentId,
          dayType: dayType,
          bucketStartMin: bucketStartMin,
          bucketEndMin: bucketEndMin,
        ),
      );
      bucket.add(event.durationSec);
    }

    return buckets.values
        .map(
          (bucket) => AggregatedSegmentStatRecord(
            segmentId: bucket.segmentId,
            dayType: bucket.dayType,
            bucketStartMin: bucket.bucketStartMin,
            bucketEndMin: bucket.bucketEndMin,
            sampleCount: bucket.sampleCount,
            averageDurationSec: bucket.averageDurationSec,
          ),
        )
        .toList(growable: false)
      ..sort((a, b) {
        final routeCompare = a.segmentId.compareTo(b.segmentId);
        if (routeCompare != 0) return routeCompare;
        final dayCompare = a.dayType.compareTo(b.dayType);
        if (dayCompare != 0) return dayCompare;
        return a.bucketStartMin.compareTo(b.bucketStartMin);
      });
  }

  String _dayType(DateTime dateTime) {
    switch (dateTime.weekday) {
      case DateTime.saturday:
        return 'saturday';
      case DateTime.sunday:
        return 'sunday';
      default:
        return 'weekday';
    }
  }
}

class _AggregateBucket {
  _AggregateBucket({
    required this.segmentId,
    required this.dayType,
    required this.bucketStartMin,
    required this.bucketEndMin,
  });

  final String segmentId;
  final String dayType;
  final int bucketStartMin;
  final int bucketEndMin;
  int sampleCount = 0;
  int _durationSum = 0;

  void add(int durationSec) {
    sampleCount++;
    _durationSum += durationSec;
  }

  double get averageDurationSec =>
      sampleCount == 0 ? 0 : _durationSum / sampleCount;
}
