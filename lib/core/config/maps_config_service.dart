import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Configuration service for Maps API keys and settings.
///
/// On web the JS API key is injected into index.html by
/// scripts/run_with_env.ps1 during run/build, so the
/// google_maps_flutter_web plugin can pick it up automatically.
/// The wrapper normalizes either GOOGLE_MAPS_API_KEY_WEB_PROD
/// or GOOGLE_MAPS_API_KEY_WEB_DEV into GOOGLE_MAPS_API_KEY_WEB
/// for the active Flutter session.
/// These getters are only needed when Dart‑side code wants to check
/// whether a key was supplied (e.g. to show a fallback widget).
class MapsConfigService {
  static bool _dotenvReady = false;

  /// Safe accessor — returns '' if dotenv was never loaded.
  static String _env(String key) {
    if (!_dotenvReady) {
      try {
        // ignore: invalid_use_of_visible_for_testing_member
        dotenv.env; // probe; throws if not initialised
        _dotenvReady = true;
      } catch (_) {
        return '';
      }
    }
    return dotenv.env[key] ?? '';
  }

  /// Web API key.
  ///
  /// Preferred path for web: pass --dart-define=GOOGLE_MAPS_API_KEY_WEB=...
  /// (or use scripts/run_with_env.ps1 which reads .env and injects the define).
  static String get webApiKey {
    const definedWeb = String.fromEnvironment(
      'GOOGLE_MAPS_API_KEY_WEB',
    );
    if (definedWeb.isNotEmpty) return definedWeb;

    const definedGeneric = String.fromEnvironment(
      'GOOGLE_MAPS_API_KEY',
    );
    if (definedGeneric.isNotEmpty) return definedGeneric;

    final fromDotenvWeb = _env('GOOGLE_MAPS_API_KEY_WEB');
    if (fromDotenvWeb.isNotEmpty) return fromDotenvWeb;

    return _env('GOOGLE_MAPS_API_KEY');
  }

  /// Android / mobile API key
  static String get androidApiKey {
    const definedAndroid = String.fromEnvironment(
      'GOOGLE_MAPS_API_KEY_ANDROID',
    );
    if (definedAndroid.isNotEmpty) return definedAndroid;

    const definedMobile = String.fromEnvironment(
      'GOOGLE_MAPS_API_KEY_MOBILE',
    );
    if (definedMobile.isNotEmpty) return definedMobile;

    final fromDotenvAndroid = _env('GOOGLE_MAPS_API_KEY_ANDROID');
    if (fromDotenvAndroid.isNotEmpty) return fromDotenvAndroid;

    return _env('GOOGLE_MAPS_API_KEY_MOBILE');
  }

  /// iOS API key
  static String get iosApiKey {
    const definedIos = String.fromEnvironment(
      'GOOGLE_MAPS_API_KEY_IOS',
    );
    if (definedIos.isNotEmpty) return definedIos;

    const definedMobile = String.fromEnvironment(
      'GOOGLE_MAPS_API_KEY_MOBILE',
    );
    if (definedMobile.isNotEmpty) return definedMobile;

    final fromDotenvIos = _env('GOOGLE_MAPS_API_KEY_IOS');
    if (fromDotenvIos.isNotEmpty) return fromDotenvIos;

    return _env('GOOGLE_MAPS_API_KEY_MOBILE');
  }

  /// True when at least the web key is available from .env
  static bool get isConfigured => webApiKey.isNotEmpty;

  /// Friendly diagnostic message (or null when everything's fine).
  static String? get configError {
    if (webApiKey.isEmpty) {
      return 'Google Maps web API key not configured. '
          'Provide GOOGLE_MAPS_API_KEY_WEB via --dart-define '
          '(or use scripts/run_with_env.ps1 which reads .env and injects it).';
    }
    return null;
  }
}
