import 'dart:async';

abstract class PollingScheduler {
  void start(Duration interval, FutureOr<void> Function() action);
  void stop();
}

class TimerPollingScheduler implements PollingScheduler {
  Timer? _timer;

  @override
  void start(Duration interval, FutureOr<void> Function() action) {
    stop();
    _timer = Timer.periodic(interval, (_) => action());
  }

  @override
  void stop() {
    _timer?.cancel();
    _timer = null;
  }
}
