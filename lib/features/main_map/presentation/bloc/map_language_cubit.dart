import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_dozor_city/core/domain/entities/app_display_language.dart';
import 'package:flutter_dozor_city/features/main_map/domain/usecases/main_map_session_use_cases.dart';

class MapLanguageState {
  const MapLanguageState({this.language = AppDisplayLanguage.en});

  final AppDisplayLanguage language;

  MapLanguageState copyWith({AppDisplayLanguage? language}) {
    return MapLanguageState(language: language ?? this.language);
  }
}

class MapLanguageCubit extends Cubit<MapLanguageState> {
  MapLanguageCubit({
    required GetMapLanguageUseCase getMapLanguageUseCase,
    required SaveMapLanguageUseCase saveMapLanguageUseCase,
  }) : _getMapLanguageUseCase = getMapLanguageUseCase,
       _saveMapLanguageUseCase = saveMapLanguageUseCase,
       super(const MapLanguageState());

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
}
