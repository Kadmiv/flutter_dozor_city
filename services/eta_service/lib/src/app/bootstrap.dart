import 'dart:async';

import 'package:shelf/shelf_io.dart' as io;

import '../config/service_config.dart';
import '../db/eta_database.dart';
import '../logging/service_logger.dart';
import '../server/app.dart';
import '../sync/batumi_sync_service.dart';

Future<void> bootstrapServer(List<String> args) async {
  final config = ServiceConfig.fromEnvironment(args: args);
  final logger = const ServiceLogger();
  logger.info(
    'Starting ETA service with db=${config.dbPath}, host=${config.host}, port=${config.port}, batumiBaseUrl=${config.batumiBaseUrl}',
  );
  final db = EtaDatabase.open(config.dbPath);
  final app = EtaHttpApp(db, logger: logger).build();
  final server = await io.serve(app, config.host, config.port);
  logger.info(
    'ETA service listening on http://${server.address.host}:${server.port}',
  );

  if (config.autoSyncEnabled) {
    final syncService = BatumiSyncService(
      database: db,
      config: config,
      logger: logger,
    );
    await syncService.refreshSnapshot();
    logger.info('Starting live poll loop every ${config.syncIntervalSeconds}s');
    unawaited(_runSyncLoop(syncService, logger, config.syncIntervalSeconds));
  } else {
    logger.info('Auto sync is disabled');
  }
}

Future<void> _runSyncLoop(
  BatumiSyncService syncService,
  ServiceLogger logger,
  int intervalSeconds,
) async {
  final interval = Duration(seconds: intervalSeconds);
  while (true) {
    try {
      await syncService.syncLiveOnce();
    } catch (error, stackTrace) {
      logger.error('Batumi sync failed: $error');
      logger.error(stackTrace.toString());
    }
    await Future.delayed(interval);
  }
}
