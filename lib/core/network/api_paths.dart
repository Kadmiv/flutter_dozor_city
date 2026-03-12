abstract final class ApiPaths {
  static const baseUrl = 'https://city.dozor.tech';

  static String cities() => '/ua/cities';
  static String cityEmblem(String cityId) => '/img/${cityId}_xdpi.png';
  static String cityMarker(String cityId, int markerIndex) =>
      '/img/${cityId}_marker_$markerIndex.png';
  static String cityRoutes() => '/data?t=1';
  static String cityDevices() => '/data?t=2';
  static String zoneArrivals() => '/data?t=3';
  static String routeSearch() => '/data?t=4';
  static String addressSuggest() => '/api/v1/geo/suggest';
}
