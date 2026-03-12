import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_dozor_city/core/di/app_scope.dart';
import 'package:flutter_dozor_city/core/router/app_router.dart';
import 'package:flutter_dozor_city/core/theme/app_theme.dart';

class DozorCityApp extends StatefulWidget {
  const DozorCityApp({super.key, required this.scope});

  final AppScope scope;

  @override
  State<DozorCityApp> createState() => _DozorCityAppState();
}

class _DozorCityAppState extends State<DozorCityApp> {
  late final AppRouter _router;

  @override
  void initState() {
    super.initState();
    _router = AppRouter(scope: widget.scope);
  }

  @override
  void dispose() {
    _router.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return RepositoryProvider<AppScope>.value(
      value: widget.scope,
      child: MaterialApp.router(
        title: 'Dozor City',
        theme: AppTheme.light(),
        routerConfig: _router.config,
      ),
    );
  }
}
