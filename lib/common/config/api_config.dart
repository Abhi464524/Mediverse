class ApiConfig {
  static const String _fromEnv = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://192.168.1.10:3500',
  );

  static String get baseUrl => _normalizeBase(_fromEnv);

  static String _normalizeBase(String raw) {
    var s = raw.trim();
    if (s.isEmpty) {
      return 'http://192.168.1.10:3500';
    }
    while (s.endsWith('/')) {
      s = s.substring(0, s.length - 1);
    }
    if (!s.endsWith('/api')) {
      s = '$s/api';
    }
    return s;
  }
}
