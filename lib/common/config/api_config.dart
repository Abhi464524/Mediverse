class ApiConfig {
  // Override with:
  // flutter run --dart-define=API_BASE_URL=http://10.0.2.2:3000/api
  static const String baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://localhost:3000/api',
  );
}
