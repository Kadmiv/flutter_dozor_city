import 'package:flutter_dozor_city/core/data/datasources/local/hive_city_local_data_source.dart';
import 'package:flutter_dozor_city/core/data/hive_session_repository.dart';
import 'package:flutter_dozor_city/core/data/hive_stored_routes_repository.dart';
import 'package:flutter_dozor_city/core/data/repositories/hive_search_draft_repository.dart';
import 'package:flutter_dozor_city/core/data/datasources/remote/dio_city_remote_data_source.dart';
import 'package:flutter_dozor_city/core/data/datasources/remote/dio_search_remote_data_source.dart';
import 'package:flutter_dozor_city/core/data/repositories/city_repository_impl.dart';
import 'package:flutter_dozor_city/core/data/repositories/search_repository_impl.dart';
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

class AppScope {
  AppScope._({
    required this.dioClient,
    required this.cityRepository,
    required this.mapController,
    required this.searchDraftRepository,
    required this.searchRepository,
    required this.sessionRepository,
    required this.storedRoutesRepository,
    required List<Box<dynamic>> openedBoxes,
  }) : _openedBoxes = openedBoxes;

  static Future<AppScope> create() async {
    await HiveBootstrap.ensureInitialized();
    final dioClient = DioClient();
    final sessionRepository = HiveSessionRepository(
      box: Hive.box<dynamic>(HiveBoxes.appSettings),
    );
    final cityLocalDataSource = HiveCityLocalDataSource(
      citiesBox: Hive.box<dynamic>(HiveBoxes.citiesCache),
      routesBox: Hive.box<dynamic>(HiveBoxes.routesCache),
    );
    return AppScope._(
      dioClient: dioClient,
      sessionRepository: sessionRepository,
      cityRepository: CityRepositoryImpl(
        remoteDataSource: DioCityRemoteDataSource(dioClient),
        localDataSource: cityLocalDataSource,
        sessionRepository: sessionRepository,
      ),
      mapController: AppMapConfiguration.currentProvider == AppMapProvider.google
          ? GoogleMapControllerAdapter()
          : FlutterMapControllerAdapter(),
      searchDraftRepository: HiveSearchDraftRepository(
        box: Hive.box<dynamic>(HiveBoxes.searchDrafts),
      ),
      searchRepository: SearchRepositoryImpl(
        remoteDataSource: DioSearchRemoteDataSource(dioClient),
      ),
      storedRoutesRepository: HiveStoredRoutesRepository(
        box: Hive.box<dynamic>(HiveBoxes.storedRoutes),
      ),
      openedBoxes: [
        Hive.box<dynamic>(HiveBoxes.appSettings),
        Hive.box<dynamic>(HiveBoxes.storedRoutes),
        Hive.box<dynamic>(HiveBoxes.citiesCache),
        Hive.box<dynamic>(HiveBoxes.routesCache),
        Hive.box<dynamic>(HiveBoxes.searchDrafts),
      ],
    );
  }

  final DioClient dioClient;
  final CityRepository cityRepository;
  final MapController mapController;
  final SearchDraftRepository searchDraftRepository;
  final SearchRepository searchRepository;
  final SessionRepository sessionRepository;
  final StoredRoutesRepository storedRoutesRepository;
  final List<Box<dynamic>> _openedBoxes;

  Future<void> dispose() async {
    sessionRepository.dispose();
    for (final box in _openedBoxes) {
      if (box.isOpen) {
        await box.close();
      }
    }
  }
}
