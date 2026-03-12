import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_dozor_city/core/domain/entities/city.dart';
import 'package:flutter_dozor_city/core/domain/repositories/session_repository.dart';
import 'package:flutter_dozor_city/core/map/app_map_camera.dart';
import 'package:flutter_dozor_city/features/main_map/domain/usecases/check_city_data_freshness_use_case.dart';

enum MainMapTab { search, results, stored }
enum MainMapMode { city, routes }

class MainMapState {
  const MainMapState({
    this.city,
    this.currentTab = MainMapTab.search,
    this.mode = MainMapMode.routes,
    this.isBottomSheetVisible = false,
    this.showMarkers = true,
    this.activeMapActionLabel,
    this.dismissedHints = const <String>{},
    this.camera,
  });

  final City? city;
  final MainMapTab currentTab;
  final MainMapMode mode;
  final bool isBottomSheetVisible;
  final bool showMarkers;
  final String? activeMapActionLabel;
  final Set<String> dismissedHints;
  final AppMapCamera? camera;

  MainMapState copyWith({
    City? city,
    MainMapTab? currentTab,
    MainMapMode? mode,
    bool? isBottomSheetVisible,
    bool? showMarkers,
    String? activeMapActionLabel,
    Set<String>? dismissedHints,
    AppMapCamera? camera,
  }) {
    return MainMapState(
      city: city ?? this.city,
      currentTab: currentTab ?? this.currentTab,
      mode: mode ?? this.mode,
      isBottomSheetVisible:
          isBottomSheetVisible ?? this.isBottomSheetVisible,
      showMarkers: showMarkers ?? this.showMarkers,
      activeMapActionLabel: activeMapActionLabel ?? this.activeMapActionLabel,
      dismissedHints: dismissedHints ?? this.dismissedHints,
      camera: camera ?? this.camera,
    );
  }
}

class MainMapCubit extends Cubit<MainMapState> {
  MainMapCubit({
    required SessionRepository sessionRepository,
    required CheckMainMapCityDataFreshnessUseCase checkCityDataFreshnessUseCase,
  })
      : _sessionRepository = sessionRepository,
        _checkCityDataFreshnessUseCase = checkCityDataFreshnessUseCase,
        super(MainMapState(city: sessionRepository.selectedCity));

  final SessionRepository _sessionRepository;
  final CheckMainMapCityDataFreshnessUseCase _checkCityDataFreshnessUseCase;

  Future<void> refresh() async {
    final city = _sessionRepository.selectedCity;
    AppMapCamera? camera;
    final dismissedHints = <String>{};
    if (city != null) {
      await _checkCityDataFreshnessUseCase(city.id);
      camera = await _sessionRepository.getMapCamera(city.id) ??
          AppMapCamera(
            centerLat: city.centerLat,
            centerLng: city.centerLng,
            zoom: city.zoom,
          );
    }
    for (final key in const ['select-city', 'map-menu', 'arrival']) {
      if (await _sessionRepository.getUiFlag(key)) {
        dismissedHints.add(key);
      }
    }
    emit(
      state.copyWith(
        city: city,
        camera: camera,
        dismissedHints: dismissedHints,
      ),
    );
  }

  void selectTab(MainMapTab tab) {
    emit(
      state.copyWith(
        currentTab: tab,
        mode: tab == MainMapTab.search ? MainMapMode.routes : state.mode,
      ),
    );
  }

  void openBottomSheet({MainMapTab? tab}) {
    emit(
      state.copyWith(
        currentTab: tab ?? state.currentTab,
        isBottomSheetVisible: true,
        mode: (tab ?? state.currentTab) == MainMapTab.search
            ? MainMapMode.routes
            : state.mode,
      ),
    );
  }

  void closeBottomSheet() {
    emit(state.copyWith(isBottomSheetVisible: false));
  }

  void toggleMarkers() {
    final next = !state.showMarkers;
    emit(
      state.copyWith(
        showMarkers: next,
        activeMapActionLabel: next ? 'Міські маркери' : 'Маркери приховані',
      ),
    );
  }

  void setRouteMode(MainMapMode mode) {
    emit(
      state.copyWith(
        mode: mode,
        isBottomSheetVisible:
            mode == MainMapMode.city ? false : state.isBottomSheetVisible,
        activeMapActionLabel: mode == MainMapMode.routes
            ? 'Режим маршрутів'
            : 'Огляд міста',
      ),
    );
  }

  void setActiveMapActionLabel(String? label) {
    emit(state.copyWith(activeMapActionLabel: label));
  }

  Future<void> dismissHint(String key) async {
    final updated = Set<String>.from(state.dismissedHints)..add(key);
    await _sessionRepository.setUiFlag(key, true);
    emit(state.copyWith(dismissedHints: updated));
  }

  Future<void> saveCamera(AppMapCamera camera) async {
    final cityId = state.city?.id;
    if (cityId == null) {
      return;
    }
    await _sessionRepository.setMapCamera(cityId, camera);
    emit(state.copyWith(camera: camera));
  }
}
