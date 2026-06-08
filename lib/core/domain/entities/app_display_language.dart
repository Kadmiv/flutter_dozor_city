enum AppDisplayLanguage { ka, en }

extension AppDisplayLanguageX on AppDisplayLanguage {
  String get code => switch (this) {
    AppDisplayLanguage.ka => 'ka',
    AppDisplayLanguage.en => 'en',
  };

  static AppDisplayLanguage fromCode(String? raw) {
    final value = raw?.trim().toLowerCase();
    return switch (value) {
      'ka' => AppDisplayLanguage.ka,
      'en' => AppDisplayLanguage.en,
      _ => AppDisplayLanguage.en,
    };
  }
}
