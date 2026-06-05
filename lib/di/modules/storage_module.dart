import 'package:hive/hive.dart';
import 'package:flutter_dozor_city/di/injector.dart';
import 'package:flutter_dozor_city/core/domain/repositories/session_repository.dart';
import 'package:flutter_dozor_city/core/domain/repositories/search_draft_repository.dart';
import 'package:flutter_dozor_city/core/domain/repositories/stored_routes_repository.dart';
import 'package:flutter_dozor_city/core/data/hive_session_repository.dart';
import 'package:flutter_dozor_city/core/storage/hive_boxes.dart';
import 'package:flutter_dozor_city/features/route_search/data/repositories/hive_search_draft_repository.dart';
import 'package:flutter_dozor_city/features/stored_routes/data/repositories/hive_stored_routes_repository.dart';

abstract final class StorageModule {
  static void register() {
    injector.registerSingleton<SessionRepository>(
      HiveSessionRepository(
        box: Hive.box<dynamic>(HiveBoxes.appSettings),
      ),
    );

    injector.registerSingleton<SearchDraftRepository>(
      HiveSearchDraftRepository(
        box: Hive.box<dynamic>(HiveBoxes.searchDrafts),
      ),
    );

    injector.registerSingleton<StoredRoutesRepository>(
      HiveStoredRoutesRepository(
        box: Hive.box<dynamic>(HiveBoxes.storedRoutes),
      ),
    );
  }
}
