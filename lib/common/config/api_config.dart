/// REST API root used by [EndPoints].
///
/// **Single source of truth at build time** — no runtime IP / URL UI. Use your
/// deployed server’s **HTTPS hostname** (e.g. `https://api.yourdomain.com/api`),
/// never a LAN IP, for store releases.
///
/// **Ways to set the URL**
/// - **CI / release:**  
///   `flutter build apk --dart-define=API_BASE_URL=https://api.yourdomain.com/api`
/// - **Local dev:** same flag, or rely on [defaultValue] below (tunnel URL).
///
/// **localtunnel:** the printed `https://….loca.lt` URL often changes each run; free
/// tier may ignore `--subdomain`. When it changes, update [defaultValue] below or use
/// `--dart-define=API_BASE_URL=...`.
///
/// [DioClient] sends `Bypass-Tunnel-Reminder: true` for `*.loca.lt` (harmless on other hosts).
class ApiConfig {
  static const String _fromEnv = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'https://mediverse-api-rathi.loca.lt/api',
  );

  /// Normalized base (trailing slashes stripped; ensures `/api` suffix).
  static String get baseUrl => _normalizeBase(_fromEnv);

  static String _normalizeBase(String raw) {
    var s = raw.trim();
    if (s.isEmpty) {
      return 'https://mediverse-api-rathi.loca.lt/api';
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
