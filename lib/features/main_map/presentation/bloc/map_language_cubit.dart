// ignore_for_file: invalid_use_of_visible_for_testing_member

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_dozor_city/core/domain/entities/app_display_language.dart';
import 'package:flutter_dozor_city/features/main_map/domain/usecases/main_map_session_use_cases.dart';

sealed class MapLanguageEvent extends Equatable {
  const MapLanguageEvent();

  @override
  List<Object?> get props => const [];
}

final class MapLanguageLoaded extends MapLanguageEvent {
  const MapLanguageLoaded();
}

final class MapLanguageSetRequested extends MapLanguageEvent {
  const MapLanguageSetRequested(this.language);

  final AppDisplayLanguage language;

  @override
  List<Object?> get props => [language];
}

final class MapLanguageToggled extends MapLanguageEvent {
  const MapLanguageToggled();
}

class MapLanguageState extends Equatable {
  const MapLanguageState({this.language = AppDisplayLanguage.en});

  final AppDisplayLanguage language;

  MapLanguageState copyWith({AppDisplayLanguage? language}) {
    return MapLanguageState(language: language ?? this.language);
  }

  @override
  List<Object?> get props => [language];
}

class MapLanguageBloc extends Bloc<MapLanguageEvent, MapLanguageState> {
  MapLanguageBloc({
    required GetMapLanguageUseCase getMapLanguageUseCase,
    required SaveMapLanguageUseCase saveMapLanguageUseCase,
  }) : _getMapLanguageUseCase = getMapLanguageUseCase,
       _saveMapLanguageUseCase = saveMapLanguageUseCase,
       super(const MapLanguageState()) {
    on<MapLanguageLoaded>(_onLoaded);
    on<MapLanguageSetRequested>(_onSetRequested);
    on<MapLanguageToggled>(_onToggled);
  }

  final GetMapLanguageUseCase _getMapLanguageUseCase;
  final SaveMapLanguageUseCase _saveMapLanguageUseCase;

  Future<void> load() async {
    emit(state.copyWith(language: await _getMapLanguageUseCase()));
  }

  Future<void> setLanguage(AppDisplayLanguage language) async {
    emit(state.copyWith(language: language));
    await _saveMapLanguageUseCase(language);
  }

  Future<void> toggle() {
    return setLanguage(
      state.language == AppDisplayLanguage.en
          ? AppDisplayLanguage.ka
          : AppDisplayLanguage.en,
    );
  }

  Future<void> _onLoaded(
    MapLanguageLoaded event,
    Emitter<MapLanguageState> emit,
  ) async {
    emit(state.copyWith(language: await _getMapLanguageUseCase()));
  }

  Future<void> _onSetRequested(
    MapLanguageSetRequested event,
    Emitter<MapLanguageState> emit,
  ) async {
    emit(state.copyWith(language: event.language));
    await _saveMapLanguageUseCase(event.language);
  }

  Future<void> _onToggled(
    MapLanguageToggled event,
    Emitter<MapLanguageState> emit,
  ) async {
    final next = state.language == AppDisplayLanguage.en
        ? AppDisplayLanguage.ka
        : AppDisplayLanguage.en;
    emit(state.copyWith(language: next));
    await _saveMapLanguageUseCase(next);
  }
}
