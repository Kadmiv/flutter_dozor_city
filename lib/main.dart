import 'package:flutter/widgets.dart';
import 'package:flutter_dozor_city/core/di/dependency_initializer.dart';
import 'package:flutter_dozor_city/app.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await DependencyInitializer.configDependencies();
  runApp(const DozorCityApp());
}
