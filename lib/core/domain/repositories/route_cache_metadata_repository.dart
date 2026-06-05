abstract class RouteCacheMetadataRepository {
  Future<int?> getRoutesCacheHash(String cityId);
  Future<void> setRoutesCacheHash(String cityId, int hash);
}
