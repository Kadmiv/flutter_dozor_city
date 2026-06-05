abstract class AppClock {
  DateTime now();
}

class SystemClock implements AppClock {
  const SystemClock();

  @override
  DateTime now() => DateTime.now();
}
