import 'package:flutter_dozor_city/di/injector.dart';
import 'package:flutter_dozor_city/core/network/dio_client.dart';

abstract final class NetworkModule {
  static void register() {
    injector.registerSingleton<DioClient>(DioClient());
  }
}
