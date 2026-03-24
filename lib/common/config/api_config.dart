class ApiConfig {
  /// REST API root used by [EndPoints].
  ///
  /// **Physical phone or tablet:** `localhost` is the device, not your PC.
  /// Use your computer’s Wi‑Fi IP (same network as the phone), e.g.
  /// `flutter run --dart-define=API_BASE_URL=http://192.168.1.42:3000/api`
  /// (replace with your machine’s IP; on macOS: `ipconfig getifaddr en0`).
  ///
  /// **Android emulator:** `flutter run --dart-define=API_BASE_URL=http://10.0.2.2:3000/api`
  ///
  /// **iOS Simulator / desktop:** default `http://localhost:3000/api` is fine.
  static const String baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://localhost:3000/api',
  );
}
