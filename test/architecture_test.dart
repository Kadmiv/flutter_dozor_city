import 'dart:io';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Architecture Tests', () {
    test('core should not depend on features', () {
      final coreDir = Directory('lib/core');
      final dartFiles = coreDir
          .listSync(recursive: true)
          .whereType<File>()
          .where((f) => f.path.endsWith('.dart'))
          .where((f) => !f.path.contains('${Platform.pathSeparator}map${Platform.pathSeparator}'));

      final errors = <String>[];

      for (final file in dartFiles) {
        final content = file.readAsStringSync();
        final lines = content.split('\n');

        for (var i = 0; i < lines.length; i++) {
          final line = lines[i];
          if (line.startsWith('import ') &&
              line.contains('package:flutter_dozor_city/features/')) {
            errors.add(
                '${file.path}:${i + 1} imports a feature module:\n  $line');
          }
        }
      }

      if (errors.isNotEmpty) {
        fail('Found violations of architecture boundaries:\n${errors.join('\n')}');
      }
    });
  });
}
