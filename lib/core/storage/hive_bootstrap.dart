import 'package:flutter_dozor_city/core/storage/hive_boxes.dart';
import 'package:hive_flutter/hive_flutter.dart';

abstract final class HiveBootstrap {
  static Future<void> ensureInitialized() async {
    if (!_initialized) {
      await Hive.initFlutter('dozor_city');
      _initialized = true;
    }

    if (!Hive.isBoxOpen(HiveBoxes.appSettings)) {
      await Hive.openBox<dynamic>(HiveBoxes.appSettings);
    }
    if (!Hive.isBoxOpen(HiveBoxes.storedRoutes)) {
      await Hive.openBox<dynamic>(HiveBoxes.storedRoutes);
    }
    if (!Hive.isBoxOpen(HiveBoxes.citiesCache)) {
      await Hive.openBox<dynamic>(HiveBoxes.citiesCache);
    }
    if (!Hive.isBoxOpen(HiveBoxes.routesCache)) {
      await Hive.openBox<dynamic>(HiveBoxes.routesCache);
    }
    if (!Hive.isBoxOpen(HiveBoxes.searchDrafts)) {
      await Hive.openBox<dynamic>(HiveBoxes.searchDrafts);
    }
  }

  static bool _initialized = false;
}
