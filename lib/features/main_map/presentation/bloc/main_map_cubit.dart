// ignore_for_file: invalid_use_of_visible_for_testing_member

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_dozor_city/core/domain/entities/city.dart';
import 'package:flutter_dozor_city/core/map/app_map_camera.dart';
import 'package:flutter_dozor_city/features/main_map/domain/usecases/check_city_data_freshness_use_case.dart';
import 'package:flutter_dozor_city/features/main_map/domain/usecases/main_map_session_use_cases.dart';

enum MainMapTab { search, results, stored }

enum MainMapMode { city, routes }

sealed class MainMapEvent extends Equatable {
  const MainMapEvent();

  @override
  List<Object?> get props => const [];
}

final class MainMapStarted extends MainMapEvent {
  const MainMapStarted({this.forceCityCenter = false});

  final bool forceCityCenter;

  @override
  List<Object?> get props => [forceCityCenter];
}

final class MainMapTabSelected extends MainMapEvent {
  const MainMapTabSelected(this.tab);

  final MainMapTab tab;

  @override
  List<Object?> get props => [tab];
}

final class MainMapBottomSheetOpened extends MainMapEvent {
  const MainMapBottomSheetOpened({this.tab});

  final MainMapTab? tab;

  @override
  List<Object?> get props => [tab];
}

final class MainMapBottomSheetClosed extends MainMapEvent {
  const MainMapBottomSheetClosed();
}

final class MainMapMarkersToggled extends MainMapEvent {
  const MainMapMarkersToggled();
}

final class MainMapRouteModeSet extends MainMapEvent {
  const MainMapRouteModeSet(this.mode);

  final MainMapMode mode;

  @override
  List<Object?> get props => [mode];
}

final class MainMapActionLabelSet extends MainMapEvent {
  const MainMapActionLabelSet(this.label);

  final String? label;

  @override
  List<Object?> get props => [label];
}

final class MainMapHintDismissed extends MainMapEvent {
  const MainMapHintDismissed(this.key);

  final String key;

  @override
  List<Object?> get props => [key];
}

final class MainMapCameraSaved extends MainMapEvent {
  const MainMapCameraSaved(this.camera);

  final AppMapCamera camera;

  @override
  List<Object?> get props => [camera];
}

class MainMapState extends Equatable {
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
      isBottomSheetVisible: isBottomSheetVisible ?? this.isBottomSheetVisible,
      showMarkers: showMarkers ?? this.showMarkers,
      activeMapActionLabel: activeMapActionLabel ?? this.activeMapActionLabel,
      dismissedHints: dismissedHints ?? this.dismissedHints,
      camera: camera ?? this.camera,
    );
  }

  @override
  List<Object?> get props => [
    city,
    currentTab,
    mode,
    isBottomSheetVisible,
    showMarkers,
    activeMapActionLabel,
    dismissedHints,
    camera,
  ];
}

class MainMapBloc extends Bloc<MainMapEvent, MainMapState> {
  MainMapBloc({
    required GetSelectedCityUseCase getSelectedCityUseCase,
    required GetMapCameraUseCase getMapCameraUseCase,
    required SaveMapCameraUseCase saveMapCameraUseCase,
    required GetUiFlagUseCase getUiFlagUseCase,
    required SetUiFlagUseCase setUiFlagUseCase,
    required CheckMainMapCityDataFreshnessUseCase checkCityDataFreshnessUseCase,
  }) : _getSelectedCityUseCase = getSelectedCityUseCase,
       _getMapCameraUseCase = getMapCameraUseCase,
       _saveMapCameraUseCase = saveMapCameraUseCase,
       _getUiFlagUseCase = getUiFlagUseCase,
       _setUiFlagUseCase = setUiFlagUseCase,
       _checkCityDataFreshnessUseCase = checkCityDataFreshnessUseCase,
       super(MainMapState(city: getSelectedCityUseCase())) {
    on<MainMapStarted>(_onStarted);
    on<MainMapTabSelected>(_onTabSelected);
    on<MainMapBottomSheetOpened>(_onBottomSheetOpened);
    on<MainMapBottomSheetClosed>(_onBottomSheetClosed);
    on<MainMapMarkersToggled>(_onMarkersToggled);
    on<MainMapRouteModeSet>(_onRouteModeSet);
    on<MainMapActionLabelSet>(_onActionLabelSet);
    on<MainMapHintDismissed>(_onHintDismissed);
    on<MainMapCameraSaved>(_onCameraSaved);
  }

  final GetSelectedCityUseCase _getSelectedCityUseCase;
  final GetMapCameraUseCase _getMapCameraUseCase;
  final SaveMapCameraUseCase _saveMapCameraUseCase;
  final GetUiFlagUseCase _getUiFlagUseCase;
  final SetUiFlagUseCase _setUiFlagUseCase;
  final CheckMainMapCityDataFreshnessUseCase _checkCityDataFreshnessUseCase;

  Future<void> refresh({bool forceCityCenter = false}) async {
    final city = _getSelectedCityUseCase();
    AppMapCamera? camera;
    final dismissedHints = <String>{};
    if (city != null) {
      await _checkCityDataFreshnessUseCase(city.id);
      camera = forceCityCenter
          ? AppMapCamera(
              centerLat: city.centerLat,
              centerLng: city.centerLng,
              zoom: city.zoom,
            )
          : await _getMapCameraUseCase(city.id) ??
                AppMapCamera(
                  centerLat: city.centerLat,
                  centerLng: city.centerLng,
                  zoom: city.zoom,
                );
    }
    for (final key in const ['select-city', 'map-menu', 'arrival']) {
      if (await _getUiFlagUseCase(key)) {
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
        isBottomSheetVisible: mode == MainMapMode.city
            ? false
            : state.isBottomSheetVisible,
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
    await _setUiFlagUseCase(key, true);
    emit(state.copyWith(dismissedHints: updated));
  }

  Future<void> saveCamera(AppMapCamera camera) async {
    final cityId = state.city?.id;
    if (cityId == null) {
      return;
    }
    await _saveMapCameraUseCase(cityId, camera);
    emit(state.copyWith(camera: camera));
  }

  Future<void> _onStarted(
    MainMapStarted event,
    Emitter<MainMapState> emit,
  ) async {
    final city = _getSelectedCityUseCase();
    AppMapCamera? camera;
    final dismissedHints = <String>{};
    if (city != null) {
      await _checkCityDataFreshnessUseCase(city.id);
      camera = event.forceCityCenter
          ? AppMapCamera(
              centerLat: city.centerLat,
              centerLng: city.centerLng,
              zoom: city.zoom,
            )
          : await _getMapCameraUseCase(city.id) ??
                AppMapCamera(
                  centerLat: city.centerLat,
                  centerLng: city.centerLng,
                  zoom: city.zoom,
                );
    }
    for (final key in const ['select-city', 'map-menu', 'arrival']) {
      if (await _getUiFlagUseCase(key)) {
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

  void _onTabSelected(
    MainMapTabSelected event,
    Emitter<MainMapState> emit,
  ) {
    emit(
      state.copyWith(
        currentTab: event.tab,
        mode: event.tab == MainMapTab.search ? MainMapMode.routes : state.mode,
      ),
    );
  }

  void _onBottomSheetOpened(
    MainMapBottomSheetOpened event,
    Emitter<MainMapState> emit,
  ) {
    emit(
      state.copyWith(
        currentTab: event.tab ?? state.currentTab,
        isBottomSheetVisible: true,
        mode: (event.tab ?? state.currentTab) == MainMapTab.search
            ? MainMapMode.routes
            : state.mode,
      ),
    );
  }

  void _onBottomSheetClosed(
    MainMapBottomSheetClosed event,
    Emitter<MainMapState> emit,
  ) {
    emit(state.copyWith(isBottomSheetVisible: false));
  }

  void _onMarkersToggled(
    MainMapMarkersToggled event,
    Emitter<MainMapState> emit,
  ) {
    final next = !state.showMarkers;
    emit(
      state.copyWith(
        showMarkers: next,
        activeMapActionLabel: next ? 'Міські маркери' : 'Маркери приховані',
      ),
    );
  }

  void _onRouteModeSet(
    MainMapRouteModeSet event,
    Emitter<MainMapState> emit,
  ) {
    emit(
      state.copyWith(
        mode: event.mode,
        isBottomSheetVisible: event.mode == MainMapMode.city
            ? false
            : state.isBottomSheetVisible,
        activeMapActionLabel: event.mode == MainMapMode.routes
            ? 'Режим маршрутів'
            : 'Огляд міста',
      ),
    );
  }

  void _onActionLabelSet(
    MainMapActionLabelSet event,
    Emitter<MainMapState> emit,
  ) {
    emit(state.copyWith(activeMapActionLabel: event.label));
  }

  Future<void> _onHintDismissed(
    MainMapHintDismissed event,
    Emitter<MainMapState> emit,
  ) async {
    final updated = Set<String>.from(state.dismissedHints)..add(event.key);
    await _setUiFlagUseCase(event.key, true);
    emit(state.copyWith(dismissedHints: updated));
  }

  Future<void> _onCameraSaved(
    MainMapCameraSaved event,
    Emitter<MainMapState> emit,
  ) async {
    final cityId = state.city?.id;
    if (cityId == null) {
      return;
    }
    await _saveMapCameraUseCase(cityId, event.camera);
    emit(state.copyWith(camera: event.camera));
  }
}
