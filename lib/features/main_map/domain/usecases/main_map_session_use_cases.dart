import 'package:flutter_dozor_city/core/domain/entities/city.dart';
import 'package:flutter_dozor_city/core/domain/entities/selected_map_routes.dart';
import 'package:flutter_dozor_city/core/map/app_map_camera.dart';
import 'package:flutter_dozor_city/core/domain/repositories/city_session_repository.dart';
import 'package:flutter_dozor_city/core/domain/repositories/map_camera_repository.dart';
import 'package:flutter_dozor_city/core/domain/repositories/session_repository.dart';
import 'package:flutter_dozor_city/core/domain/repositories/ui_flags_repository.dart';

class GetSelectedCityUseCase {
  const GetSelectedCityUseCase(this._repository);
  final CitySessionRepository _repository;
  City? call() => _repository.selectedCity;
}

class GetMapCameraUseCase {
  const GetMapCameraUseCase(this._repository);
  final MapCameraRepository _repository;
  Future<AppMapCamera?> call(String cityId) => _repository.getMapCamera(cityId);
}

class SaveMapCameraUseCase {
  const SaveMapCameraUseCase(this._repository);
  final MapCameraRepository _repository;
  Future<void> call(String cityId, AppMapCamera camera) => _repository.setMapCamera(cityId, camera);
}

class GetUiFlagUseCase {
  const GetUiFlagUseCase(this._repository);
  final UiFlagsRepository _repository;
  Future<bool> call(String key) => _repository.getUiFlag(key);
}

class SetUiFlagUseCase {
  const SetUiFlagUseCase(this._repository);
  final UiFlagsRepository _repository;
  Future<void> call(String key, bool value) => _repository.setUiFlag(key, value);
}

class GetSelectedMapRoutesUseCase {
  const GetSelectedMapRoutesUseCase(this._repository);
  final SessionRepository _repository;
  Future<SelectedMapRoutes?> call(String cityId) =>
      _repository.getSelectedMapRoutes(cityId);
}

class SaveSelectedMapRoutesUseCase {
  const SaveSelectedMapRoutesUseCase(this._repository);
  final SessionRepository _repository;
  Future<void> call(
    String cityId,
    SelectedMapRoutes selectedMapRoutes,
  ) =>
      _repository.setSelectedMapRoutes(cityId, selectedMapRoutes);
}
