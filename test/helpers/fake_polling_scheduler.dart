import 'dart:async';
import 'package:flutter_dozor_city/core/time/polling_scheduler.dart';

class FakePollingScheduler implements PollingScheduler {
  @override
  void start(Duration interval, FutureOr<void> Function() action) {
    // In tests, we don't actually poll, or we can trigger it manually if needed.
  }

  @override
  void stop() {}
}
