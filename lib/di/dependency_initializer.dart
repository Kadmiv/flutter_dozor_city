import 'package:flutter_dozor_city/core/storage/hive_bootstrap.dart';
import 'package:flutter_dozor_city/di/modules/core_module.dart';
import 'package:flutter_dozor_city/di/modules/data_module.dart';
import 'package:flutter_dozor_city/di/modules/features_module.dart';
import 'package:flutter_dozor_city/di/modules/network_module.dart';
import 'package:flutter_dozor_city/di/modules/storage_module.dart';

class DependencyInitializer {
  static const bool isDemo = bool.fromEnvironment('DEMO', defaultValue: false);

  static Future<void> configDependencies() async {
    await HiveBootstrap.ensureInitialized();
    NetworkModule.register();
    StorageModule.register();
    CoreModule.register();
    DataModule.register(isDemo: isDemo);
    FeaturesModule.register();
  }
}
