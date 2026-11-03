import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Values from the bundled `.env` asset (see `.env.example`). Everything here
/// is public: the file ships inside the app.
///
/// There are no built-in fallbacks. A missing `.env` fails the build (it is a
/// declared asset), and a missing or empty value throws at startup, so a
/// misconfigured build can never quietly talk to the wrong server.
class AppEnv {
  AppEnv._();

  static const required = ['GOOGLE_WEB_CLIENT_ID', 'DEV_API_BACKEND_URL', 'PROD_API_BACKEND_URL'];

  /// Loads `.env` and checks every required key is filled in.
  static Future<void> load() async {
    await dotenv.load(fileName: '.env');
    final missing = required.where((k) => _value(k) == null).toList();
    if (missing.isNotEmpty) {
      throw StateError('.env is missing values for: ${missing.join(', ')}. See .env.example.');
    }
  }

  static String? _value(String key) {
    final v = dotenv.env[key]?.trim();
    return v == null || v.isEmpty || v.startsWith('your-') ? null : v;
  }

  static String _require(String key) =>
      _value(key) ?? (throw StateError('$key is not set in .env. See .env.example.'));

  /// `--dart-define=API_ENV=prod` points a debug build at production
  /// without editing `.env` (`API_ENV=dev` does the reverse for release).
  static const _apiEnv = String.fromEnvironment('API_ENV');

  /// API root including `/api/v1`. Release builds use PROD, debug and profile
  /// builds use DEV; [_apiEnv] overrides the build-mode choice.
  static String get apiBaseUrl {
    final useProd = switch (_apiEnv) { 'prod' => true, 'dev' => false, _ => kReleaseMode };
    final host = _require(useProd ? 'PROD_API_BACKEND_URL' : 'DEV_API_BACKEND_URL');
    return '${host.replaceAll(RegExp(r'/+$'), '')}/api/v1';
  }

  /// OAuth web client id, used as Google sign-in's serverClientId.
  static String get googleWebClientId => _require('GOOGLE_WEB_CLIENT_ID');
}
