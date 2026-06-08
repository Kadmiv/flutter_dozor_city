import 'dart:io';

import 'package:shelf/shelf_io.dart' as io;

import '../config/service_config.dart';
import '../db/eta_database.dart';
import '../logging/service_logger.dart';
import '../server/app.dart';

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
}
