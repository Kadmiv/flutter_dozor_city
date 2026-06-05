abstract class AppFailure implements Exception {
  const AppFailure(this.message);
  final String message;

  @override
  String toString() => 'AppFailure: $message';
}

class NetworkFailure extends AppFailure {
  const NetworkFailure([super.message = 'Network error occurred.']);
}

class CacheMissFailure extends AppFailure {
  const CacheMissFailure([super.message = 'Requested data not found in cache.']);
}

class UnsupportedPlatformFailure extends AppFailure {
  const UnsupportedPlatformFailure([super.message = 'This feature is not supported on the current platform.']);
}

class ParseFailure extends AppFailure {
  const ParseFailure([super.message = 'Failed to parse data.']);
}
