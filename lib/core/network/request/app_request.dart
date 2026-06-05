enum AppRequestMethod { get, post, put, patch, delete }

abstract class AppRequest {
  const AppRequest({
    required this.method,
    required this.path,
    this.baseUrl,
    this.queryParameters,
    this.data,
    this.headers,
    this.cityCookieId,
  });

  final AppRequestMethod method;
  final String path;
  final String? baseUrl;
  final Map<String, dynamic>? queryParameters;
  final Object? data;
  final Map<String, dynamic>? headers;
  final String? cityCookieId;
}
