import 'dart:io';

class ServiceLogger {
  const ServiceLogger();

  void info(String message) {
    stdout.writeln('${_timestamp()} [INFO] $message');
  }

  void warn(String message) {
    stdout.writeln('${_timestamp()} [WARN] $message');
  }

  void error(String message) {
    stderr.writeln('${_timestamp()} [ERROR] $message');
  }

  String _timestamp() => DateTime.now().toIso8601String();
}
