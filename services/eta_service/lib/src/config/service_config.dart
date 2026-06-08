import 'dart:io';

import 'package:args/args.dart';
import 'package:path/path.dart' as p;

class ServiceConfig {
  const ServiceConfig({
    required this.dbPath,
    required this.host,
    required this.port,
    required this.batumiBaseUrl,
    required this.autoSyncEnabled,
    required this.syncIntervalSeconds,
  });

  final String dbPath;
  final String host;
  final int port;
  final String batumiBaseUrl;
  final bool autoSyncEnabled;
  final int syncIntervalSeconds;

  factory ServiceConfig.fromEnvironment({List<String> args = const []}) {
    final parser = ArgParser()
      ..addOption('db-path')
      ..addOption('runtime-dir')
      ..addOption('host')
      ..addOption('port')
      ..addOption('batumi-base-url')
      ..addOption('auto-sync')
      ..addOption('sync-interval-seconds')
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
      autoSyncEnabled: _bool(
        parsed['auto-sync'] as String? ?? Platform.environment['ETA_AUTO_SYNC'],
        defaultValue: true,
      ),
      syncIntervalSeconds: _syncIntervalSeconds(
        parsed['sync-interval-seconds'] as String? ??
            Platform.environment['ETA_SYNC_INTERVAL_SECONDS'] ??
            Platform.environment['ETA_SYNC_INTERVAL_MINUTES'],
      ),
    );
  }

  static String _projectRoot() {
    final scriptPath = Platform.script.toFilePath();
    return p.dirname(p.dirname(scriptPath));
  }

  static bool _bool(String? raw, {required bool defaultValue}) {
    if (raw == null || raw.trim().isEmpty) {
      return defaultValue;
    }
    final value = raw.trim().toLowerCase();
    return value == '1' || value == 'true' || value == 'yes' || value == 'on';
  }

  static int _syncIntervalSeconds(String? raw) {
    if (raw == null || raw.trim().isEmpty) {
      return 5;
    }
    final parsed = int.tryParse(raw);
    if (parsed == null || parsed <= 0) {
      return 5;
    }
    if (Platform.environment['ETA_SYNC_INTERVAL_SECONDS'] != null) {
      return parsed;
    }
    if (Platform.environment['ETA_SYNC_INTERVAL_MINUTES'] != null) {
      return parsed * 60;
    }
    return parsed;
  }
}
