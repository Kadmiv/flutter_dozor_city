# flutter_dozor_city

Flutter port of Dozor City with `BLoC`, clean architecture, `Dio`, `Hive`, `go_router` and `google_maps_flutter`.

## Run

1. Install Flutter dependencies:
```bash
flutter pub get
```

2. Provide Google Maps API keys.

Android:
- Replace `GOOGLE_MAPS_API_KEY` in [android/gradle.properties](/Users/devel/Downloads/dozor_city/flutter_dozor_city/android/gradle.properties).

iOS:
- Copy [MapsKeys.xcconfig.example](/Users/devel/Downloads/dozor_city/flutter_dozor_city/ios/Flutter/MapsKeys.xcconfig.example) to `ios/Flutter/MapsKeys.xcconfig`.
- Put `GOOGLE_MAPS_API_KEY=your_key` into that file.
- [ios/Runner/Info.plist](/Users/devel/Downloads/dozor_city/flutter_dozor_city/ios/Runner/Info.plist) already reads it through `$(GOOGLE_MAPS_API_KEY)`.

3. Run the app:
```bash
flutter run
```

## Notes

- Android and iOS platform folders were generated from Flutter tooling and now include Google Maps runtime hooks.
- Without valid API keys the map widget will not work correctly on device.
- Current runtime ids are configured as `ua.dozorcity.app` and should be adjusted if the final release ids differ.
