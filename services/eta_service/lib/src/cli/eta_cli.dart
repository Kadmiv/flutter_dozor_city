import 'dart:io';

import 'package:args/args.dart';

import '../analysis/segment_load_analyzer.dart';
import '../batumi/batumi_api_client.dart';
import '../config/service_config.dart';
import '../db/eta_database.dart';
import '../export/json_stats_exporter.dart';
import '../logging/service_logger.dart';
import '../sync/batumi_sync_service.dart';

Future<void> runEtaCli(List<String> args) async {
  if (args.isEmpty) {
    _usage();
    exitCode = 64;
    return;
  }

  final command = args.first;
  final config = ServiceConfig.fromEnvironment(
    args: args.skip(1).toList(growable: false),
  );
  final logger = const ServiceLogger();
  final database = EtaDatabase.open(config.dbPath);

  try {
    switch (command) {
      case 'migrate':
        logger.info('SQLite schema ready at ${config.dbPath}');
        break;
      case 'import-batumi':
        await _importBatumi(database, config, logger);
        break;
      case 'poll-batumi':
        await _pollBatumi(
          database,
          config,
          logger,
          args.skip(1).toList(growable: false),
        );
        break;
      case 'export-json':
        await _exportJson(
          database,
          logger,
          args.skip(1).toList(growable: false),
        );
        break;
      case 'analyze-segments':
        await _analyzeSegments(
          database,
          logger,
          args.skip(1).toList(growable: false),
        );
        break;
      case 'sync-batumi':
        await _syncBatumi(database, config, logger);
        break;
      default:
        _usage();
        exitCode = 64;
        break;
    }
  } finally {
    database.close();
  }
}

Future<void> _importBatumi(
  EtaDatabase database,
  ServiceConfig config,
  ServiceLogger logger,
) async {
  final client = BatumiApiClient(baseUrl: config.batumiBaseUrl, logger: logger);
  logger.info('Importing Batumi snapshot from ${config.batumiBaseUrl}');
  final snapshot = await client.loadSnapshot();
  logger.info(
    'Parsed Batumi snapshot: routes=${snapshot.routes.length}, stops=${snapshot.stops.length}, routeStops=${snapshot.routeStops.length}, polylines=${snapshot.routePolylines.length}',
  );
  database.replaceSnapshot(snapshot);
  logger.info('Saved Batumi snapshot to SQLite at ${config.dbPath}');
}

Future<void> _pollBatumi(
  EtaDatabase database,
  ServiceConfig config,
  ServiceLogger logger,
  List<String> args,
) async {
  final parser = _buildParser()..addOption('route-id');
  final result = parser.parse(args);
  final routeId = result['route-id'] as String? ?? '';
  if (routeId.isEmpty) {
    stderr.writeln('Missing --route-id');
    exitCode = 64;
    return;
  }
  final client = BatumiApiClient(baseUrl: config.batumiBaseUrl, logger: logger);
  logger.info('Polling Batumi API for route $routeId');
  final positions = await client.pollRoute(routeId);
  logger.info(
    'Parsed ${positions.length} active vehicles from ${config.batumiBaseUrl}/api/getBusLocsOnRoute?routeId=$routeId',
  );
  final inserted = database.insertGpsPositions(positions);
  logger.info(
    'Saved $inserted new GPS positions to SQLite at ${config.dbPath}',
  );
}

Future<void> _exportJson(
  EtaDatabase database,
  ServiceLogger logger,
  List<String> args,
) async {
  final parser = _buildParser()..addOption('out');
  final result = parser.parse(args);
  final outPath = result['out'] as String? ?? '';
  if (outPath.isEmpty) {
    stderr.writeln('Missing --out');
    exitCode = 64;
    return;
  }
  final exporter = JsonStatsExporter(outPath);
  logger.info('Exporting SQLite snapshot to JSON at $outPath');
  await exporter.publishSnapshot(database);
  logger.info('Exported snapshot to $outPath');
}

Future<void> _analyzeSegments(
  EtaDatabase database,
  ServiceLogger logger,
  List<String> args,
) async {
  final parser = _buildParser()..addOption('route-id');
  final result = parser.parse(args);
  final routeId = result['route-id'] as String?;
  final analyzer = SegmentLoadAnalyzer(logger: logger);
  logger.info(
    routeId == null || routeId.isEmpty
        ? 'Analyzing segment load for all routes with GPS data'
        : 'Analyzing segment load for route $routeId',
  );
  final analysisResult = analyzer.analyze(database, routeId: routeId);
  logger.info(
    'Segment analysis complete: routes=${analysisResult.routeCount}, gps=${analysisResult.gpsRead}, matched=${analysisResult.matchedPoints}, segmentEvents=${analysisResult.segmentEvents}, aggregatedRows=${analysisResult.aggregatedRows}',
  );
}

Future<void> _syncBatumi(
  EtaDatabase database,
  ServiceConfig config,
  ServiceLogger logger,
) async {
  final syncService = BatumiSyncService(
    database: database,
    config: config,
    logger: logger,
  );
  logger.info(
    'Running one-shot Batumi sync: snapshot refresh plus live poll, no segment analysis',
  );
  await syncService.syncOnce();
}

void _usage() {
  stderr.writeln(
    'Usage: migrate | import-batumi | poll-batumi --route-id <id> | sync-batumi | analyze-segments [--route-id <id>] | export-json --out <path>',
  );
}

ArgParser _buildParser() {
  final parser = ArgParser()
    ..addOption('db-path')
    ..addOption('host')
    ..addOption('port')
    ..addOption('batumi-base-url');
  return parser;
}
