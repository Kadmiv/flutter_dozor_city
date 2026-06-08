import 'package:eta_service/src/batumi/batumi_api_client.dart';
import 'package:eta_service/src/config/service_config.dart';
import 'package:eta_service/src/db/eta_database.dart';
import 'package:eta_service/src/domain/models.dart';
import 'package:eta_service/src/logging/service_logger.dart';
import 'package:eta_service/src/sync/batumi_sync_service.dart';
import 'package:test/test.dart';

import 'helpers/sample_route_data.dart';

class _FakeBatumiClient extends BatumiApiClient {
  _FakeBatumiClient() : super(baseUrl: 'https://example.invalid');

  @override
  Future<BatumiSnapshot> loadSnapshot() async => buildSampleSnapshot();

  @override
  Future<List<GpsPosition>> pollRoute(String routeId) async {
    if (routeId != sampleRouteId) {
      return const [];
    }
    return buildForwardSamplePositions();
  }
}

void main() {
  test(
    'sync-batumi imports snapshot, polls routes and analyzes segments',
    () async {
      final db = EtaDatabase.open(':memory:');
      addTearDown(db.close);

      final config = ServiceConfig(
        dbPath: ':memory:',
        host: '127.0.0.1',
        port: 8080,
        batumiBaseUrl: 'https://example.invalid',
        autoSyncEnabled: false,
        syncIntervalSeconds: 5,
      );

      final service = BatumiSyncService(
        database: db,
        config: config,
        logger: const ServiceLogger(),
        client: _FakeBatumiClient(),
      );

      final summary = await service.syncOnce();

      expect(summary.routeCount, 1);
      expect(summary.polledRoutes, 1);
      expect(summary.positionsFetched, 4);
      expect(summary.positionsInserted, 4);
      expect(db.getSegmentEvents(routeId: sampleRouteId), isEmpty);
      expect(db.getAggregatedSegmentStats(routeId: sampleRouteId), isEmpty);
      expect(db.listGpsPositions(routeId: sampleRouteId), hasLength(4));
    },
  );
}
