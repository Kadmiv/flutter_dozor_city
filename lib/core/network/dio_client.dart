import 'package:flutter/foundation.dart';
import 'package:dio/dio.dart';
import 'package:flutter_dozor_city/core/network/api_paths.dart';

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
