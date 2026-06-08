import 'dart:convert';
import 'dart:io';

import '../db/eta_database.dart';

abstract class StatsPublisher {
  Future<void> publishSnapshot(EtaDatabase database);
}

class JsonStatsExporter implements StatsPublisher {
  JsonStatsExporter(this.outputPath);

  final String outputPath;

  @override
  Future<void> publishSnapshot(EtaDatabase database) async {
    final file = File(outputPath);
    await file.create(recursive: true);
    await file.writeAsString(
      const JsonEncoder.withIndent('  ').convert(database.snapshotJson()),
    );
  }
}
