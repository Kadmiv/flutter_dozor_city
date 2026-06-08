import 'dart:io';

import 'package:args/args.dart';
import 'package:path/path.dart' as p;

class ServiceConfig {
  const ServiceConfig({
    required this.dbPath,
    required this.host,
    required this.port,
    required this.batumiBaseUrl,
  });

  final String dbPath;
  final String host;
  final int port;
  final String batumiBaseUrl;

  factory ServiceConfig.fromEnvironment({List<String> args = const []}) {
    final parser = ArgParser()
      ..addOption('db-path')
      ..addOption('runtime-dir')
      ..addOption('host')
      ..addOption('port')
      ..addOption('batumi-base-url')
      ..addOption('route-id')
      ..addOption('out');
    final parsed = parser.parse(args);

    final projectRoot = _projectRoot();
    final runtimeDir =
        parsed['runtime-dir'] as String? ??
        Platform.environment['ETA_RUNTIME_DIR'] ??
        p.join(projectRoot, 'runtime');
    final dbPath =
        parsed['db-path'] as String? ??
        Platform.environment['ETA_DB_PATH'] ??
        p.join(runtimeDir, 'eta_service.db');

    return ServiceConfig(
      dbPath: dbPath,
      host:
          parsed['host'] as String? ??
          Platform.environment['ETA_HOST'] ??
          '0.0.0.0',
      port:
          int.tryParse(
            (parsed['port'] as String?) ??
                Platform.environment['ETA_PORT'] ??
                '8080',
          ) ??
          8080,
      batumiBaseUrl:
          parsed['batumi-base-url'] as String? ??
          Platform.environment['BATUMI_BASE_URL'] ??
          'https://thetamaps.site:54321',
    );
  }

  static String _projectRoot() {
    final scriptPath = Platform.script.toFilePath();
    return p.dirname(p.dirname(scriptPath));
  }
}
