import 'package:hive/hive.dart';
import 'package:flutter_dozor_city/di/injector.dart';
import 'package:flutter_dozor_city/core/domain/repositories/city_repository.dart';
import 'package:flutter_dozor_city/core/domain/repositories/search_repository.dart';
import 'package:flutter_dozor_city/core/domain/repositories/session_repository.dart';
import 'package:flutter_dozor_city/core/time/app_clock.dart';
import 'package:flutter_dozor_city/core/network/dio_client.dart';
import 'package:flutter_dozor_city/core/storage/hive_boxes.dart';
import 'package:flutter_dozor_city/features/city_data/data/datasources/local/hive_city_local_data_source.dart';
import 'package:flutter_dozor_city/features/city_data/data/datasources/remote/batumi_remote_data_source.dart';
import 'package:flutter_dozor_city/features/city_data/data/datasources/remote/composite_city_remote_data_source.dart';
import 'package:flutter_dozor_city/features/city_data/data/datasources/remote/dio_city_remote_data_source.dart';
import 'package:flutter_dozor_city/features/city_data/data/repositories/city_repository_impl.dart';
import 'package:flutter_dozor_city/features/city_data/data/repositories/in_memory_city_repository.dart';
import 'package:flutter_dozor_city/features/route_search/data/datasources/remote/dio_search_remote_data_source.dart';
import 'package:flutter_dozor_city/features/route_search/data/repositories/in_memory_search_repository.dart';
import 'package:flutter_dozor_city/features/route_search/data/repositories/search_repository_impl.dart';

abstract final class DataModule {
  static void register({required bool isDemo}) {
    if (isDemo) {
      injector.registerSingleton<CityRepository>(InMemoryCityRepository());
      injector.registerSingleton<SearchRepository>(InMemorySearchRepository());
      return;
    }

    final cityLocalDataSource = HiveCityLocalDataSource(
      citiesBox: Hive.box<dynamic>(HiveBoxes.citiesCache),
      routesBox: Hive.box<dynamic>(HiveBoxes.routesCache),
    );

    injector.registerSingleton<CityRepository>(
      CityRepositoryImpl(
        remoteDataSource: CompositeCityRemoteDataSource(
          dozorRemoteDataSource: DioCityRemoteDataSource(injector<DioClient>()),
          batumiRemoteDataSource: BatumiRemoteDataSource(injector<DioClient>()),
        ),
        localDataSource: cityLocalDataSource,
        sessionRepository: injector<SessionRepository>(),
        clock: injector<AppClock>(),
      ),
    );

    injector.registerSingleton<SearchRepository>(
      SearchRepositoryImpl(
        remoteDataSource: DioSearchRemoteDataSource(injector<DioClient>()),
      ),
    );
  }
}
