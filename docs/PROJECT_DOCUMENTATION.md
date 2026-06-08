# Документация проекта Dozor City Flutter

Документ описывает, что находится в проекте, где искать основные части системы, как приложение запускается, как идут данные, какие фичи уже реализованы и как работает отдельный ETA-сервис.

## 1. Назначение проекта

`flutter_dozor_city` — Flutter-клиент для городского транспорта. Приложение позволяет выбрать город, смотреть транспорт на карте, выбирать маршруты, видеть остановки и прогноз прибытия, строить маршрут между двумя точками и сохранять полезные варианты маршрутов.

Основной стек:

- Flutter и Material UI.
- `go_router` для навигации.
- `flutter_bloc` для состояния экранов и фич.
- `get_it` для dependency injection.
- `Dio` для HTTP-запросов.
- `Hive` для локальных настроек, кеша, черновиков и избранных маршрутов.
- Абстракция карты с двумя реализациями: Google Maps и OpenStreetMap через `flutter_map`.
- Отдельный Dart-сервис `services/eta_service` для сбора GPS-данных Batumi, хранения в SQLite и экспорта JSON.

## 2. Точки входа

### Flutter-приложение

- `lib/main.dart`
  - Инициализирует Flutter bindings.
  - Вызывает `DependencyInitializer.configDependencies()`.
  - Запускает `DozorCityApp`.

- `lib/app.dart`
  - Создает `MaterialApp.router`.
  - Подключает `AppTheme.light()`.
  - Использует `AppRouter`.

- `lib/router/app_router.dart`
  - Создает корневой `GoRouter`.
  - Начальный путь: `/main-map/search`.
  - Если город не выбран, отправляет пользователя на `/select-city`.
  - Если город уже выбран, не дает оставаться на `/select-city` и возвращает на `/main-map/search`.
  - Подключает роуты из feature-роутеров.

### ETA-сервис

- `services/eta_service/bin/eta_service.dart`
  - CLI-команды для миграций, импорта Batumi, polling и экспорта JSON.

- `services/eta_service/bin/server.dart`
  - HTTP-сервер для health-check, приема GPS и чтения GPS-данных.

## 3. Как приложение запускается

1. `main()` запускает инициализацию.
2. `DependencyInitializer` открывает Hive boxes и регистрирует зависимости.
3. `AppRouter` проверяет `SessionRepository.hasSelectedCity`.
4. Если город не выбран, открывается `/select-city`.
5. После выбора города приложение переходит в `/main-map/search`.
6. `MainMapOrchestrator` поднимает состояние карты:
   - загружает выбранный город;
   - проверяет актуальность городских данных;
   - восстанавливает сохраненную камеру;
   - восстанавливает выбранные маршруты;
   - запускает polling транспорта;
   - применяет камеру к карте.
7. Далее shell карты остается на экране, а вложенные страницы переключаются между поиском, результатами и сохраненными маршрутами.

## 4. Структура проекта

### Корень

- `lib/` — код Flutter-приложения.
- `test/` — unit/widget-тесты.
- `android/`, `ios/`, `web/` — платформенные директории Flutter.
- `services/eta_service/` — отдельный Dart backend/collector.
- `pubspec.yaml` — зависимости приложения.
- `analysis_options.yaml` — правила анализа.
- `README.md` — краткая инструкция запуска.

### `lib/core`

Общие сущности, контракты и инфраструктура.

- `core/domain/entities/`
  - Основные сущности: `City`, `TransportRoute`, `Vehicle`, `RouteZone`, `ArrivalInfo`, `RouteArrival`, `RouteResult`, `SelectedPoint`, `SearchParams`, `SelectedMapRoutes`, `RoutePreviewSegment`.

- `core/domain/repositories/`
  - Контракты репозиториев: города, маршруты, прибытия, транспорт, сессия, камера, UI-флаги, черновик поиска, сохраненные маршруты.

- `core/data/`
  - Общие реализации: `HiveSessionRepository`, `InMemorySessionRepository`, fake seed data.

- `core/network/`
  - `DioClient`, `ApiPaths`, базовый `AppRequest`.

- `core/storage/`
  - `HiveBootstrap`, `HiveBoxes`.

- `core/map/`
  - Общая карта, контроллеры, адаптеры Google Maps и Flutter Map.

- `core/time/`
  - `AppClock`, `PollingScheduler`.

- `core/error/`
  - Модель ошибок/failures.

- `core/router/`
  - Имена роутов, аргументы роутов, интерфейс `FeatureRouter`.

### `lib/di`

Регистрация зависимостей.

- `dependency_initializer.dart`
  - Общий bootstrap.
  - Поддерживает demo-режим через `--dart-define=DEMO=true`.

- `modules/network_module.dart`
  - Регистрирует `DioClient`.

- `modules/storage_module.dart`
  - Регистрирует Hive-backed session, search draft и stored routes.

- `modules/core_module.dart`
  - Регистрирует clock, polling scheduler и map controller.

- `modules/data_module.dart`
  - В demo-режиме подключает in-memory репозитории.
  - В обычном режиме подключает `CityRepositoryImpl` и `SearchRepositoryImpl`.

- `modules/features_module.dart`
  - Регистрирует use cases и cubits всех фич.

### `lib/features`

Фичи приложения. Каждая фича хранит свой presentation/domain/data слой, если он нужен.

## 5. Фичи приложения

### 5.1 Выбор города

Где находится:

- `features/city_selection/presentation/pages/select_city_page.dart`
- `features/city_selection/presentation/widgets/city_picker_content.dart`
- `features/city_selection/presentation/bloc/city_selection_cubit.dart`
- `features/city_selection/domain/usecases/get_cities_use_case.dart`
- `features/city_selection/domain/usecases/select_city_use_case.dart`
- `features/city_selection/domain/usecases/check_city_data_freshness_use_case.dart`
- `features/city_selection/presentation/router/city_selection_router.dart`

Как работает:

- `CitySelectionCubit.loadCities()` загружает список городов.
- `selectCity(city)` сохраняет выбранный город через `SessionRepository`.
- После сохранения `SessionRepository` уведомляет router, и приложение переходит к основной карте.
- Этот же UI используется из main map как bottom sheet для смены города.

### 5.2 Главная карта

Где находится:

- `features/main_map/presentation/router/main_map_router.dart`
- `features/main_map/presentation/router/main_map_orchestrator.dart`
- `features/main_map/presentation/pages/main_map_page.dart`
- `features/main_map/presentation/widgets/main_map_components.dart`
- `features/main_map/presentation/widgets/map_state_listener.dart`
- `features/main_map/presentation/bloc/main_map_cubit.dart`
- `features/main_map/presentation/bloc/map_routes_cubit.dart`
- `features/main_map/presentation/bloc/map_arrivals_cubit.dart`
- `features/main_map/presentation/bloc/map_overlays_cubit.dart`

Что делает:

- Держит постоянный shell карты.
- Показывает верхнее меню города/режима.
- Показывает выбранные маршруты.
- Показывает нижнюю панель типов транспорта.
- Открывает bottom sheets: города, маршруты, остановки, детали транспорта.
- Сохраняет позицию камеры по городу.
- Хранит скрытые подсказки интерфейса.
- Синхронизирует выбор маршрутов с live tracking.

Главные cubits:

- `MainMapCubit`
  - выбранный город;
  - текущая вкладка;
  - режим `city/routes`;
  - видимость bottom sheet;
  - видимость маркеров;
  - текст активного действия;
  - скрытые подсказки;
  - камера карты.

- `MapRoutesCubit`
  - выбранный тип транспорта;
  - доступные маршруты;
  - выбранные маршруты;
  - активный маршрут;
  - активный город;
  - loading/failure.

- `MapArrivalsCubit`
  - остановки активного маршрута;
  - активная остановка;
  - прогноз прибытия;
  - polling прогноза каждые 15 секунд.

- `MapOverlaysCubit`
  - старый объединенный state для маршрутов/остановок/прибытия. Сейчас основная карта в основном использует разделенные `MapRoutesCubit` и `MapArrivalsCubit`.

### 5.3 Live tracking транспорта

Где находится:

- `features/live_tracking/presentation/bloc/live_tracking_cubit.dart`
- `features/live_tracking/domain/usecases/get_city_vehicles_use_case.dart`
- `features/live_tracking/domain/services/live_vehicle_motion_resolver.dart`
- `features/live_tracking/domain/entities/animated_vehicle.dart`
- `features/live_tracking/presentation/widgets/vehicle_marker_widget.dart`
- `features/live_tracking/presentation/widgets/vehicle_marker_layer.dart`
- `features/live_tracking/presentation/widgets/vehicle_details_sheet.dart`

Как работает:

- `LiveTrackingCubit.start(cityId)` запускает polling транспорта.
- Интервал polling: 10 секунд.
- Можно грузить весь транспорт города или фильтровать по выбранным route ids.
- `LiveVehicleMotionResolver` превращает новые координаты в `AnimatedVehicle`.
- Если движение выглядит реалистично, маркер плавно едет между точками.
- Если маршрут/тип изменился, расстояние слишком маленькое или расчетная скорость выше лимита, маркер мгновенно переносится.

Параметры анимации:

- default duration: 10 секунд.
- minimum duration: 800 ms.
- maximum duration: 12 секунд.
- minimum animated distance: 3 метра.
- maximum urban speed: 90 км/ч.

### 5.4 Выбор маршрутов, остановки и прибытия

Где находится:

- `features/main_map/presentation/widgets/map_overlays/routes_sheet.dart`
- `features/main_map/presentation/widgets/map_overlays/stops_sheet.dart`
- `features/main_map/presentation/widgets/map_overlays/arrival_info_panel.dart`
- `features/main_map/presentation/widgets/map_overlays/route_zones_wrap.dart`
- `features/main_map/domain/usecases/get_routes_by_type_use_case.dart`
- `features/main_map/domain/usecases/get_route_zones_use_case.dart`
- `features/main_map/domain/usecases/get_arrival_by_zone_use_case.dart`

Сценарий:

1. Пользователь нажимает тип транспорта внизу карты.
2. `MapRoutesCubit.selectTransportType()` загружает маршруты выбранного типа.
3. Открывается `RoutesSheet`.
4. Пользователь выбирает один или несколько маршрутов.
5. Выбранные маршруты отображаются чипами и, если есть геометрия, линиями на карте.
6. Live tracking фильтруется по выбранным маршрутам.
7. Пользователь открывает `StopsSheet`.
8. Тап по остановке вызывает `MapArrivalsCubit.loadArrival()`.
9. Прогноз прибытия обновляется каждые 15 секунд.

### 5.5 Поиск маршрута между точками

Где находится:

- `features/route_search/presentation/pages/route_search_page.dart`
- `features/route_search/presentation/bloc/route_search_cubit.dart`
- `features/route_search/domain/usecases/load_search_draft_use_case.dart`
- `features/route_search/domain/usecases/save_search_draft_use_case.dart`
- `features/route_search/domain/usecases/swap_search_points_use_case.dart`
- `features/route_search/domain/usecases/toggle_transport_type_use_case.dart`
- `features/route_search/domain/usecases/validate_route_search_use_case.dart`
- `features/route_search/data/repositories/hive_search_draft_repository.dart`

Что делает:

- Позволяет выбрать точку "от" и "до".
- Позволяет включать/выключать типы транспорта.
- Сохраняет черновик поиска в Hive.
- Меняет точки местами.
- Валидирует, что обе точки выбраны и есть хотя бы один тип транспорта.
- Переходит на `/main-map/results` с `RouteResultsArgs`.

Формат legacy payload для поиска:

```text
startLng,startLat,endLng,endLat,type0-type1-type2-type3-type4
```

### 5.6 Выбор точки

Где находится:

- `features/point_select/presentation/pages/point_select_page.dart`
- `features/point_select/presentation/bloc/point_select_cubit.dart`
- `features/point_select/domain/usecases/search_address_suggestions_use_case.dart`
- `features/point_select/domain/usecases/get_current_location_use_case.dart`
- `features/point_select/data/models/selected_point_model.dart`

Что делает:

- Открывается как dialog/page из поиска маршрута.
- Ищет адресные подсказки.
- Возвращает `SelectedPoint`.
- `useCurrentLocation()` есть в интерфейсе use case, но в текущей Dio-реализации не подключен к device location и бросает `UnimplementedError`.

### 5.7 Результаты поиска маршрута

Где находится:

- `features/route_results/presentation/pages/route_results_page.dart`
- `features/route_results/presentation/bloc/route_results_cubit.dart`
- `features/route_results/presentation/widgets/legacy_route_card.dart`
- `features/route_results/domain/usecases/search_routes_use_case.dart`
- `features/route_results/domain/usecases/toggle_stored_route_use_case.dart`
- `features/route_search/data/mappers/search_route_result_mapper.dart`

Что делает:

- Загружает варианты маршрута по `SearchParams`.
- Мапит legacy API response в `RouteResult`.
- Помечает уже сохраненные маршруты.
- Позволяет сохранить/удалить маршрут из сохраненных.
- Слушает изменения `StoredRoutesRepository`, чтобы состояние `isStored` оставалось актуальным.

### 5.8 Превью маршрута

Где находится:

- `features/route_preview/presentation/bloc/route_preview_cubit.dart`
- `features/route_preview/presentation/widgets/route_preview_map_layer.dart`
- `features/route_preview/presentation/widgets/route_preview_panel.dart`
- `features/route_preview/domain/usecases/build_preview_camera_use_case.dart`

Что делает:

- Рисует preview geometry на карте.
- Показывает start/end markers.
- Использует тот же map abstraction, что и основная карта.

### 5.9 Сохраненные маршруты

Где находится:

- `features/stored_routes/presentation/pages/stored_routes_page.dart`
- `features/stored_routes/presentation/bloc/stored_routes_cubit.dart`
- `features/stored_routes/domain/usecases/get_stored_routes_use_case.dart`
- `features/stored_routes/domain/usecases/watch_stored_routes_use_case.dart`
- `features/stored_routes/domain/usecases/delete_stored_route_use_case.dart`
- `features/stored_routes/data/repositories/hive_stored_routes_repository.dart`

Что делает:

- Показывает список сохраненных `RouteResult`.
- Удаляет сохраненные маршруты.
- Использует `ChangeNotifier` в repository, чтобы UI результатов и UI сохраненных маршрутов синхронизировались.

## 6. Городские данные

Где находится:

- `features/city_data/data/repositories/city_repository_impl.dart`
- `features/city_data/data/datasources/local/hive_city_local_data_source.dart`
- `features/city_data/data/datasources/remote/composite_city_remote_data_source.dart`
- `features/city_data/data/datasources/remote/dio_city_remote_data_source.dart`
- `features/city_data/data/datasources/remote/batumi_remote_data_source.dart`
- `features/city_data/data/api/city_api.dart`
- `features/city_data/data/batumi/batumi_api.dart`

Что предоставляет:

- список городов;
- маршруты по типу транспорта;
- остановки/зоны маршрута;
- прогноз прибытия по остановке;
- live vehicles;
- проверку актуальности городских данных.

Кеши в `CityRepositoryImpl`:

- список городов: 24 часа;
- маршруты по типу: 6 часов;
- остановки маршрута: 6 часов;
- прибытия: 20 секунд.

Проверка свежести:

- `ensureCityDataFresh(cityId)` получает remote hash.
- Если hash совпадает с сохраненным, кеш не трогается.
- Если hash изменился, локальные данные города очищаются, новый hash сохраняется.
- Если remote hash недоступен, приложение продолжает работать с текущим кешем.

## 7. Навигация

Имена роутов:

- `core/router/app_route_names.dart`

Роутеры:

- `CitySelectionRouter`
  - `/select-city`

- `MainMapRouter`
  - shell route с постоянным `MainMapOrchestrator`;
  - `/main-map/search`;
  - `/main-map/results`;
  - `/main-map/stored`.

- `PointSelectRouter`
  - `/point-select`;
  - в текущем UX точка чаще открывается как dialog из `RouteSearchPage`.

Важные правила:

- Начальный путь приложения: `/main-map/search`.
- Без выбранного города пользователь попадает на `/select-city`.
- Результаты маршрута получают параметры через `RouteResultsArgs` в `GoRouterState.extra`.

## 8. API и источники данных

### Legacy Dozor City API

Base URL:

```text
https://city.dozor.tech
```

Пути:

- `/ua/cities` — список городов.
- `/data?t=1` — маршруты и статические данные города.
- `/data?t=2` — устройства/транспорт.
- `/data?t=3` — прибытия по остановке/зоне.
- `/data?t=4` — поиск маршрута.
- `/api/v1/geo/suggest` — адресные подсказки.
- `/img/{cityId}_xdpi.png` — эмблема города.
- `/img/{cityId}_marker_{markerIndex}.png` — маркер города.

Ограничение Flutter Web:

- Legacy city API требует cookie `gts.web.city`.
- В браузере приложение не может выставлять этот cookie так же, как native/desktop.
- Поэтому `DioCityRemoteDataSource` на web бросает `UnsupportedError` для city-specific legacy запросов.
- Для web нужен proxy/backend, который будет работать с этим cookie.

### Batumi API

ETA-сервис по умолчанию использует:

```text
https://thetamaps.site:54321
```

App-side Batumi datasource использует:

- `/api/getDbData` — snapshot маршрутов и остановок.
- `/api/getPointsBetweenStations` — геометрия маршрутов.
- `/api/getBusLocsOnRoute` — live buses на маршруте.
- `/api/getLiveData` — прибытия по маршруту/остановке.

Особенности Batumi:

- Batumi добавляется в список городов даже если legacy список его не вернул.
- Сейчас Batumi маршруты представлены как автобусы, transport type `0`.
- Цвет маршрута генерируется из identity маршрута.
- Прибытия по остановке собираются из live data всех маршрутов, которые обслуживают остановку.

## 9. Локальное хранилище

Hive инициализируется в:

- `core/storage/hive_bootstrap.dart`

Boxes:

- `app_settings`
  - выбранный город;
  - hash кеша маршрутов по городу;
  - выбранный тип транспорта;
  - выбранные маршруты;
  - активный маршрут;
  - камера карты;
  - скрытые UI-подсказки.

- `stored_routes`
  - сохраненные `RouteResult`.

- `cities_cache`
  - кеш списка городов и timestamp обновления.

- `routes_cache`
  - маршруты по city/type;
  - остановки маршрута;
  - прибытия.

- `search_drafts`
  - черновик поиска маршрута.

Важно:

- Проект хранит в Hive обычные maps/lists, без generated Hive adapters.
- Поэтому обратная совместимость схемы зависит от reader/writer кода в репозиториях.
- `HiveSessionRepository` уведомляет listeners при смене города, и это обновляет router.

## 10. Карта

Где находится:

- `core/map/app_map_surface.dart`
- `core/map/app_map_provider.dart`
- `core/map/map_controller.dart`
- `core/map/google_map_surface.dart`
- `core/map/flutter_map_surface.dart`
- `core/map/google_map_controller_adapter.dart`
- `core/map/flutter_map_controller_adapter.dart`
- `core/map/in_memory_map_controller.dart`

Текущий provider:

```dart
AppMapConfiguration.currentProvider = AppMapProvider.openStreetMap;
```

Что умеет общий слой:

- переключать Google Maps и OpenStreetMap;
- рисовать live markers;
- рисовать polyline выбранных маршрутов;
- рисовать preview route geometry;
- показывать start/end markers;
- сохранять camera idle позицию;
- обновлять moving markers с frame timer 100 ms.

Google Maps:

- Android key: `android/gradle.properties`, `GOOGLE_MAPS_API_KEY`.
- iOS key: скопировать `ios/Flutter/MapsKeys.xcconfig.example` в `ios/Flutter/MapsKeys.xcconfig` и задать `GOOGLE_MAPS_API_KEY`.
- Без валидных ключей Google map не будет нормально работать на устройстве.

OpenStreetMap:

- Используется `flutter_map`.
- Tile URL: `https://tile.openstreetmap.org/{z}/{x}/{y}.png`.
- Google key не нужен.

## 11. Dependency Injection

Порядок регистрации:

1. `HiveBootstrap.ensureInitialized()`
2. `NetworkModule.register()`
3. `StorageModule.register()`
4. `CoreModule.register()`
5. `DataModule.register(isDemo: isDemo)`
6. `FeaturesModule.register()`

Особенности:

- `CoreModule` выбирает map controller по `AppMapConfiguration.currentProvider`.
- Если город уже выбран, map controller получает начальную камеру по центру города.
- `FeaturesModule` регистрирует use cases и cubits как factories.

Demo mode:

```bash
flutter run --dart-define=DEMO=true
```

В demo mode:

- `CityRepository` — `InMemoryCityRepository`.
- `SearchRepository` — `InMemorySearchRepository`.
- Сетевые city/search данные не используются.

## 12. Ошибки и fallback

Где находится:

- `core/error/failures.dart`

Паттерн:

- Репозитории бросают `AppFailure`.
- Cubits ловят `AppFailure` и кладут в state.
- Неожиданные исключения обычно заворачиваются в `ParseFailure`.
- `MapStateListener` показывает snackbar для ошибок map-related cubits.

Fallback:

- City/routes/zones/arrival сначала читаются из кеша.
- Если remote request упал, но кеш есть, возвращается кеш.
- Если кеша нет, выбрасывается failure.

## 13. ETA Service

Где находится:

- `services/eta_service`

Для чего нужен:

- собирать Batumi GPS positions;
- хранить static route/stop snapshot и live positions в SQLite;
- принимать GPS через HTTP;
- отдавать GPS query;
- экспортировать JSON snapshot.

Конфигурация:

- `ETA_DB_PATH`, default: `$HOME/.eta_service/eta_service.db`.
- `ETA_HOST`, default: `0.0.0.0`.
- `ETA_PORT`, default: `8080`.
- `BATUMI_BASE_URL`, default: `https://thetamaps.site:54321`.

Команды:

```bash
cd services/eta_service
dart run bin/eta_service.dart migrate
dart run bin/eta_service.dart import-batumi
dart run bin/eta_service.dart poll-batumi --route-id 123
dart run bin/eta_service.dart export-json --out ./snapshot.json
dart run bin/server.dart
```

HTTP endpoints:

- `GET /health`
  - Возвращает `{"ok": true}`.

- `POST /gps`
  - Принимает один GPS position JSON.
  - Валидирует обязательные поля.
  - Вставляет запись с dedupe.

- `POST /gps/batch`
  - Принимает массив GPS positions.
  - Вставляет валидные записи с dedupe.

- `GET /gps?vehicleId=...&routeId=...&limit=100`
  - Возвращает последние GPS записи.
  - `limit` ограничивается диапазоном `1..1000`.

SQLite tables:

- `gps_positions`
- `routes`
- `stops`
- `route_stops`
- `route_polylines`
- `segment_events`
- `aggregated_segment_stats`

## 14. Запуск и проверка

Установить зависимости:

```bash
flutter pub get
```

Запустить приложение:

```bash
flutter run
```

Запустить demo mode:

```bash
flutter run --dart-define=DEMO=true
```

Запустить тесты:

```bash
flutter test
```

Запустить analyzer:

```bash
flutter analyze
```

Собрать debug APK:

```bash
flutter build apk --debug
```

Проверить ETA service:

```bash
cd services/eta_service
dart test
```

## 15. Тесты

Основные зоны тестирования:

- `test/architecture_test.dart`
  - архитектурные ограничения.

- `test/core/data/mappers/`
  - mapping legacy route search/result JSON.

- `test/core/data/models/`
  - parsing route devices JSON.

- `test/core/presentation/`
  - генерация цветов маршрутов.

- `test/features/...`
  - cubits, pages, repositories, datasource parsing, Batumi resolver, live vehicle motion, map overlays.

- `services/eta_service/test/`
  - HTTP server, Batumi API client, CLI, SQLite database.

## 16. Типовые задачи разработки

### Добавить новый экран

1. Создать page/widget в `lib/features/<feature>/presentation`.
2. Добавить cubit/use cases, если нужна логика.
3. Зарегистрировать зависимости в `FeaturesModule`.
4. Добавить feature router или расширить существующий.
5. Добавить route name в `core/router/app_route_names.dart`.
6. Добавить тесты для cubit и важных UI-состояний.

### Добавить новый API-запрос

1. Добавить path в `core/network/api_paths.dart` или feature-specific paths.
2. Создать request object в `data/requests`.
3. Добавить метод в API wrapper.
4. Обновить remote datasource contract.
5. Добавить DTO и mapper в domain entity.
6. При необходимости добавить cache/fallback в repository.
7. Написать parser/repository tests.

### Добавить новое кешируемое значение

1. Выбрать существующий Hive box или добавить новый в `HiveBoxes`.
2. Открыть box в `HiveBootstrap`.
3. Добавить read/write методы в repository.
4. Использовать versioned keys, если схема может меняться.
5. Покрыть missing/old/valid values тестами.

### Добавить нового city provider

1. Реализовать `CityRemoteDataSource`.
2. Добавить provider-specific API wrapper и DTO.
3. Подключить provider в `CompositeCityRemoteDataSource`.
4. Реализовать `getCities`, `getRoutesByType`, `getRouteZones`, `getArrivalByZone`, `getCityVehicles`, `getCityDataHash`, `preloadCityData`.
5. Определить hash/cache invalidation поведение.
6. Добавить тесты parsing, route identity, vehicle mapping и arrivals.

### Переключить map provider

1. Обновить `AppMapConfiguration.currentProvider` в `core/map/app_map_provider.dart`.
2. Убедиться, что `CoreModule` регистрирует нужный controller adapter.
3. Для Google Maps настроить platform API keys.
4. Проверить markers, polylines, preview geometry и camera persistence.

## 17. Известные ограничения

- Flutter Web не может напрямую использовать legacy Dozor city cookie flow.
- Current location в `DioSearchRemoteDataSource` пока не подключен к device location.
- `MapOverlaysCubit` выглядит как legacy/combined overlay state; актуальная карта использует `MapRoutesCubit` и `MapArrivalsCubit`.
- Hive хранит raw maps/lists, поэтому миграции схемы нужно делать аккуратно.
- Batumi сейчас bus-oriented и не возвращает маршруты для non-bus transport types.
- `DioClient` включает подробный `LogInterceptor` с request/response body.

## 18. Быстрый справочник

- Bootstrap приложения: `lib/main.dart`
- App widget: `lib/app.dart`
- Router: `lib/router/app_router.dart`
- DI bootstrap: `lib/di/dependency_initializer.dart`
- DI modules: `lib/di/modules/`
- API paths: `lib/core/network/api_paths.dart`
- HTTP client: `lib/core/network/dio_client.dart`
- Hive bootstrap: `lib/core/storage/hive_bootstrap.dart`
- Map provider switch: `lib/core/map/app_map_provider.dart`
- Main map shell: `lib/features/main_map/presentation/pages/main_map_page.dart`
- Main map orchestration: `lib/features/main_map/presentation/router/main_map_orchestrator.dart`
- Live tracking: `lib/features/live_tracking/presentation/bloc/live_tracking_cubit.dart`
- City repository: `lib/features/city_data/data/repositories/city_repository_impl.dart`
- Legacy remote data: `lib/features/city_data/data/datasources/remote/dio_city_remote_data_source.dart`
- Batumi remote data: `lib/features/city_data/data/datasources/remote/batumi_remote_data_source.dart`
- Route search: `lib/features/route_search/presentation/bloc/route_search_cubit.dart`
- Route results: `lib/features/route_results/presentation/bloc/route_results_cubit.dart`
- Stored routes: `lib/features/stored_routes/data/repositories/hive_stored_routes_repository.dart`
- ETA service: `services/eta_service`

