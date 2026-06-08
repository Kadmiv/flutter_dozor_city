import '../db/eta_database.dart';
import '../logging/service_logger.dart';
import 'route_matcher.dart';
import 'segment_analyzer.dart';
import 'statistics_aggregator.dart';

class SegmentLoadAnalysisResult {
  const SegmentLoadAnalysisResult({
    required this.routeCount,
    required this.gpsRead,
    required this.matchedPoints,
    required this.segmentEvents,
    required this.aggregatedRows,
  });

  final int routeCount;
  final int gpsRead;
  final int matchedPoints;
  final int segmentEvents;
  final int aggregatedRows;
}

class SegmentLoadAnalyzer {
  SegmentLoadAnalyzer({
    RouteMatcher? matcher,
    SegmentAnalyzer? segmentAnalyzer,
    StatisticsAggregator? statisticsAggregator,
    ServiceLogger? logger,
  }) : _matcher = matcher ?? RouteMatcher(),
       _segmentAnalyzer = segmentAnalyzer ?? SegmentAnalyzer(matcher: matcher),
       _statisticsAggregator = statisticsAggregator ?? StatisticsAggregator(),
       _logger = logger ?? const ServiceLogger();

  final RouteMatcher _matcher;
  final SegmentAnalyzer _segmentAnalyzer;
  final StatisticsAggregator _statisticsAggregator;
  final ServiceLogger _logger;

  SegmentLoadAnalysisResult analyze(EtaDatabase database, {String? routeId}) {
    final routeIds = routeId != null && routeId.isNotEmpty
        ? <String>[routeId]
        : database.getRouteIdsWithGpsData();
    var gpsRead = 0;
    var matchedPoints = 0;
    var segmentEvents = 0;
    var aggregatedRows = 0;
    var analyzedRoutes = 0;

    for (final currentRouteId in routeIds) {
      final track = database.loadRouteTrack(currentRouteId);
      if (track == null) {
        _logger.warn(
          'Skipping route $currentRouteId because route data is missing',
        );
        continue;
      }

      final positions = database.listGpsPositions(
        routeId: currentRouteId,
        ascending: true,
        limit: 100000,
      );
      analyzedRoutes++;
      gpsRead += positions.length;

      database.deleteAnalysisForRoute(currentRouteId);
      final routeMatchedPoints = positions
          .where((position) => _matcher.match(track, position) != null)
          .length;
      matchedPoints += routeMatchedPoints;
      final events = _segmentAnalyzer.buildEvents(track, positions);
      segmentEvents += events.length;
      database.insertSegmentEvents(events);

      final stats = _statisticsAggregator.aggregate(events);
      aggregatedRows += stats.length;
      database.replaceAggregatedSegmentStats(stats);

      _logger.info(
        'Analyzed route $currentRouteId: gps=${positions.length}, matched=$routeMatchedPoints, segmentEvents=${events.length}, aggregatedRows=${stats.length}',
      );
    }

    return SegmentLoadAnalysisResult(
      routeCount: analyzedRoutes,
      gpsRead: gpsRead,
      matchedPoints: matchedPoints,
      segmentEvents: segmentEvents,
      aggregatedRows: aggregatedRows,
    );
  }
}
