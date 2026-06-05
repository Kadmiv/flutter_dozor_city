import 'package:flutter/foundation.dart';
import 'package:dio/dio.dart';
import 'package:flutter_dozor_city/core/network/api_paths.dart';
import 'package:flutter_dozor_city/core/network/request/app_request.dart';

class DioClient {
  DioClient()
      : dio = Dio(
          BaseOptions(
            baseUrl: ApiPaths.baseUrl,
            connectTimeout: const Duration(seconds: 10),
            receiveTimeout: const Duration(seconds: 10),
            sendTimeout: kIsWeb ? null : const Duration(seconds: 10),
            responseType: ResponseType.json,
            headers: kIsWeb
                ? const {
                    'Accept-Encoding': 'gzip',
                  }
                : const {
                    'User-Agent': 'Mozilla/5.0',
                    'Accept-Encoding': 'gzip',
                    'Connection': 'Keep-Alive',
                  },
          ),
        ) {
    dio.interceptors.add(
      LogInterceptor(
        requestBody: true,
        responseBody: true,
      ),
    );
  }

  final Dio dio;
  bool get supportsLegacyCityCookie => !kIsWeb;

  Future<Response<dynamic>> request(AppRequest request) {
    final options = Options(
      method: request.method.name.toUpperCase(),
      headers: {
        ...?request.headers,
        if (supportsLegacyCityCookie && request.cityCookieId != null)
          'Cookie': 'gts.web.city=${request.cityCookieId}',
      },
    );
    return dio.request<dynamic>(
      request.path,
      data: request.data,
      queryParameters: request.queryParameters,
      options: options,
    );
  }

  Options cityCookieOptions(String cityId) {
    if (!supportsLegacyCityCookie) {
      return Options();
    }
    return Options(
      headers: {
        'Cookie': 'gts.web.city=$cityId',
      },
    );
  }
}
