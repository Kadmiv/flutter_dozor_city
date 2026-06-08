import 'package:collection/collection.dart';

import '../domain/models.dart';
import 'route_matcher.dart';

class SegmentAnalysisResult {
  const SegmentAnalysisResult({
    required this.gpsRead,
    required this.matchedPoints,
    required this.segmentEvents,
  });

  final int gpsRead;
  final int matchedPoints;
  final int segmentEvents;
}

class SegmentAnalyzer {
  SegmentAnalyzer({
    RouteMatcher? matcher,
    this.maxEventDurationSec = 4 * 60 * 60,
    this.reverseResetThresholdMs = 15 * 60 * 1000,
  }) : _matcher = matcher ?? RouteMatcher();

  final RouteMatcher _matcher;
  final int maxEventDurationSec;
  final int reverseResetThresholdMs;

  SegmentAnalysisResult analyze(
    RouteTrackData track,
    List<GpsPosition> positions,
  ) {
    final analysis = _analyze(track, positions);

    return SegmentAnalysisResult(
      gpsRead: positions.length,
      matchedPoints: analysis.matchedPoints,
      segmentEvents: analysis.events.length,
    );
  }

  List<SegmentEventRecord> buildEvents(
    RouteTrackData track,
    List<GpsPosition> positions,
  ) {
    return _analyze(track, positions).events;
  }

  _TrackAnalysis _analyze(RouteTrackData track, List<GpsPosition> positions) {
    final grouped = groupBy(
      positions.toList(growable: false)
        ..sort((a, b) => a.timestampMs.compareTo(b.timestampMs)),
      (GpsPosition position) => position.vehicleId,
    );

    var matchedPoints = 0;
    final events = <SegmentEventRecord>[];
    for (final vehiclePositions in grouped.values) {
      final vehicleResult = _analyzeVehicle(track, vehiclePositions);
      matchedPoints += vehicleResult.matchedPoints;
      events.addAll(vehicleResult.events);
    }
    return _TrackAnalysis(matchedPoints: matchedPoints, events: events);
  }

  _VehicleAnalysis _analyzeVehicle(
    RouteTrackData track,
    List<GpsPosition> positions,
  ) {
    final matchedSamples = <_MatchedSample>[];
    for (final position in positions) {
      final match = _matcher.match(track, position);
      if (match == null) {
        continue;
      }
      matchedSamples.add(
        _MatchedSample(
          vehicleId: position.vehicleId,
          timestampMs: position.timestampMs,
          segmentIndex: match.segmentIndex,
          segmentId: match.segmentId,
          progressMeters: match.progressMeters,
        ),
      );
    }

    final events = <SegmentEventRecord>[];
    if (matchedSamples.isEmpty) {
      return _VehicleAnalysis(matchedPoints: 0, events: events);
    }

    _MatchedSample? current;
    for (final sample in matchedSamples) {
      if (current == null) {
        current = sample;
        continue;
      }
      final gapMs = sample.timestampMs - current.lastTimestampMs;
      if (sample.segmentIndex < current.segmentIndex &&
          gapMs <= reverseResetThresholdMs) {
        continue;
      }
      if (sample.segmentId == current.segmentId) {
        current = current.copyWith(lastTimestampMs: sample.timestampMs);
        continue;
      }

      _appendEvent(events, current);
      current = sample;
    }

    if (current != null) {
      _appendEvent(events, current);
    }

    return _VehicleAnalysis(
      matchedPoints: matchedSamples.length,
      events: events,
    );
  }

  void _appendEvent(List<SegmentEventRecord> events, _MatchedSample sample) {
    final durationSec = ((sample.lastTimestampMs - sample.startedAtMs) / 1000)
        .round();
    if (durationSec <= 0 || durationSec > maxEventDurationSec) {
      return;
    }
    events.add(
      SegmentEventRecord(
        vehicleId: sample.vehicleId,
        segmentId: sample.segmentId,
        startedAtMs: sample.startedAtMs,
        finishedAtMs: sample.lastTimestampMs,
        durationSec: durationSec,
      ),
    );
  }
}

class _TrackAnalysis {
  const _TrackAnalysis({required this.matchedPoints, required this.events});

  final int matchedPoints;
  final List<SegmentEventRecord> events;
}

class _VehicleAnalysis {
  const _VehicleAnalysis({required this.matchedPoints, required this.events});

  final int matchedPoints;
  final List<SegmentEventRecord> events;
}

class _MatchedSample {
  const _MatchedSample({
    required this.vehicleId,
    required this.timestampMs,
    required this.segmentIndex,
    required this.segmentId,
    required this.progressMeters,
    int? startedAtMs,
    int? lastTimestampMs,
  }) : startedAtMs = startedAtMs ?? timestampMs,
       lastTimestampMs = lastTimestampMs ?? timestampMs;

  final String vehicleId;
  final int timestampMs;
  final int startedAtMs;
  final int lastTimestampMs;
  final int segmentIndex;
  final String segmentId;
  final double progressMeters;

  _MatchedSample copyWith({int? startedAtMs, int? lastTimestampMs}) {
    return _MatchedSample(
      vehicleId: vehicleId,
      timestampMs: timestampMs,
      startedAtMs: startedAtMs ?? this.startedAtMs,
      lastTimestampMs: lastTimestampMs ?? this.lastTimestampMs,
      segmentIndex: segmentIndex,
      segmentId: segmentId,
      progressMeters: progressMeters,
    );
  }
}
