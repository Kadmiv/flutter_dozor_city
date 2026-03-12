import 'package:flutter/widgets.dart';
import 'package:flutter_dozor_city/core/di/app_scope.dart';
import 'package:flutter_dozor_city/app.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final scope = await AppScope.create();
  runApp(DozorCityApp(scope: scope));
}
