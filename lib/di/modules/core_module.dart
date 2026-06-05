import 'package:flutter_dozor_city/di/injector.dart';
import 'package:flutter_dozor_city/core/domain/repositories/session_repository.dart';
import 'package:flutter_dozor_city/core/map/app_map_camera.dart';
import 'package:flutter_dozor_city/core/map/app_map_provider.dart';
import 'package:flutter_dozor_city/core/map/flutter_map_controller_adapter.dart';
import 'package:flutter_dozor_city/core/map/google_map_controller_adapter.dart';
import 'package:flutter_dozor_city/core/map/map_controller.dart';
import 'package:flutter_dozor_city/core/time/app_clock.dart';
import 'package:flutter_dozor_city/core/time/polling_scheduler.dart';

abstract final class CoreModule {
  static void register() {
    injector.registerSingleton<AppClock>(const SystemClock());
    injector.registerFactory<PollingScheduler>(() => TimerPollingScheduler());

    final mapController = AppMapConfiguration.currentProvider == AppMapProvider.google
        ? GoogleMapControllerAdapter()
        : FlutterMapControllerAdapter();

    final lastCity = injector<SessionRepository>().selectedCity;
    if (lastCity != null) {
      mapController.cacheCamera(
        AppMapCamera(
          centerLat: lastCity.centerLat,
          centerLng: lastCity.centerLng,
          zoom: lastCity.zoom,
        ),
      );
    }
    injector.registerSingleton<MapController>(mapController);
  }
}
