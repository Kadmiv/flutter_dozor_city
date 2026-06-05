abstract class UiFlagsRepository {
  Future<bool> getUiFlag(String key);
  Future<void> setUiFlag(String key, bool value);
}
