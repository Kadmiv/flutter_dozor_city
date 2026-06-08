import '../batumi/batumi_api_client.dart';
import '../config/service_config.dart';
import '../db/eta_database.dart';
import '../logging/service_logger.dart';

class BatumiSyncSummary {
  const BatumiSyncSummary({
    required this.routeCount,
    required this.polledRoutes,
    required this.positionsFetched,
    required this.positionsInserted,
  });

  final int routeCount;
  final int polledRoutes;
  final int positionsFetched;
  final int positionsInserted;
}

class BatumiSyncService {
  BatumiSyncService({
    required EtaDatabase database,
    required ServiceConfig config,
    required ServiceLogger logger,
    BatumiApiClient? client,
  }) : _database = database,
       _config = config,
       _logger = logger,
       _client =
           client ??
           BatumiApiClient(baseUrl: config.batumiBaseUrl, logger: logger);

  final EtaDatabase _database;
  final ServiceConfig _config;
  final ServiceLogger _logger;
  final BatumiApiClient _client;

  Future<BatumiSyncSummary> refreshSnapshot() async {
    _logger.info('Refreshing Batumi route snapshot');
    final snapshot = await _client.loadSnapshot();
    _database.replaceSnapshot(snapshot);
    _logger.info(
      'Route snapshot refreshed: routes=${snapshot.routes.length}, stops=${snapshot.stops.length}',
    );
    return BatumiSyncSummary(
      routeCount: snapshot.routes.length,
      polledRoutes: 0,
      positionsFetched: 0,
      positionsInserted: 0,
    );
  }

  Future<BatumiSyncSummary> syncOnce() async {
    _logger.info('Starting Batumi sync cycle');
    await refreshSnapshot();
    return syncLiveOnce();
  }

  Future<BatumiSyncSummary> syncLiveOnce() async {
    _logger.info('Starting Batumi live poll cycle');
    final routeIds = _database.getRouteIds();
    var positionsFetched = 0;
    var positionsInserted = 0;
    var polledRoutes = 0;
    for (final routeId in routeIds) {
      final positions = await _client.pollRoute(routeId);
      positionsFetched += positions.length;
      positionsInserted += _database.insertGpsPositions(positions);
      polledRoutes++;
    }

    final summary = BatumiSyncSummary(
      routeCount: routeIds.length,
      polledRoutes: polledRoutes,
      positionsFetched: positionsFetched,
      positionsInserted: positionsInserted,
    );

    _logger.info(
      'Batumi live poll complete: routes=${summary.routeCount}, polled=${summary.polledRoutes}, fetched=${summary.positionsFetched}, inserted=${summary.positionsInserted}',
    );
    return summary;
  }
}
