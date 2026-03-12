enum AppMapProvider {
  google,
  openStreetMap,
}

class AppMapConfiguration {
  static AppMapProvider currentProvider = AppMapProvider.openStreetMap;
}
