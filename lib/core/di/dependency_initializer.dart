import 'package:flutter_dozor_city/core/data/datasources/local/hive_city_local_data_source.dart';
import 'package:flutter_dozor_city/core/data/hive_session_repository.dart';
import 'package:flutter_dozor_city/core/data/hive_stored_routes_repository.dart';
import 'package:flutter_dozor_city/core/data/repositories/hive_search_draft_repository.dart';
import 'package:flutter_dozor_city/core/data/datasources/remote/dio_city_remote_data_source.dart';
import 'package:flutter_dozor_city/core/data/datasources/remote/dio_search_remote_data_source.dart';
import 'package:flutter_dozor_city/core/data/repositories/city_repository_impl.dart';
import 'package:flutter_dozor_city/core/data/repositories/search_repository_impl.dart';
import 'package:flutter_dozor_city/core/di/injector.dart';
import 'package:flutter_dozor_city/core/map/app_map_provider.dart';
import 'package:flutter_dozor_city/core/map/google_map_controller_adapter.dart';
import 'package:flutter_dozor_city/core/map/flutter_map_controller_adapter.dart';
import 'package:flutter_dozor_city/core/map/map_controller.dart';
import 'package:flutter_dozor_city/core/network/dio_client.dart';
import 'package:flutter_dozor_city/core/domain/repositories/city_repository.dart';
import 'package:flutter_dozor_city/core/domain/repositories/search_draft_repository.dart';
import 'package:flutter_dozor_city/core/domain/repositories/search_repository.dart';
import 'package:flutter_dozor_city/core/domain/repositories/session_repository.dart';
import 'package:flutter_dozor_city/core/domain/repositories/stored_routes_repository.dart';
import 'package:flutter_dozor_city/core/storage/hive_bootstrap.dart';
import 'package:flutter_dozor_city/core/storage/hive_boxes.dart';
import 'package:hive/hive.dart';

import '../map/app_map_camera.dart';

class DependencyInitializer {
  static Future<void> configDependencies() async {
    await HiveBootstrap.ensureInitialized();

    final dioClient = DioClient();
    injector.registerSingleton<DioClient>(dioClient);

    final sessionRepository = HiveSessionRepository(
      box: Hive.box<dynamic>(HiveBoxes.appSettings),
    );
    injector.registerSingleton<SessionRepository>(sessionRepository);

    final cityLocalDataSource = HiveCityLocalDataSource(
      citiesBox: Hive.box<dynamic>(HiveBoxes.citiesCache),
      routesBox: Hive.box<dynamic>(HiveBoxes.routesCache),
    );

    injector.registerSingleton<CityRepository>(
      CityRepositoryImpl(
        remoteDataSource: DioCityRemoteDataSource(dioClient),
        localDataSource: cityLocalDataSource,
        sessionRepository: sessionRepository,
      ),
    );

    final mapController = AppMapConfiguration.currentProvider == AppMapProvider.google
        ? GoogleMapControllerAdapter()
        : FlutterMapControllerAdapter();

    final lastCity = sessionRepository.selectedCity;
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

    injector.registerSingleton<SearchDraftRepository>(
      HiveSearchDraftRepository(
        box: Hive.box<dynamic>(HiveBoxes.searchDrafts),
      ),
    );

    injector.registerSingleton<SearchRepository>(
      SearchRepositoryImpl(
        remoteDataSource: DioSearchRemoteDataSource(dioClient),
      ),
    );

    injector.registerSingleton<StoredRoutesRepository>(
      HiveStoredRoutesRepository(
        box: Hive.box<dynamic>(HiveBoxes.storedRoutes),
      ),
    );
  }
}
