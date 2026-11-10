import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';

import 'crash_reporter.dart';

/// Crashlytics behind [CrashReporter]. Every call is best-effort: reporting
/// must never be the thing that breaks the app.
class FirebaseCrashReporter implements CrashReporter {
  FirebaseCrashReporter(this._c);

  final FirebaseCrashlytics _c;

  @override
  Future<void> recordError(Object error, StackTrace? stack, {String? reason}) async {
    try {
      await _c.recordError(error, stack, reason: reason, fatal: false);
    } catch (e) {
      debugPrint('crashlytics recordError failed: $e');
    }
  }

  @override
  Future<void> setUserId(String? id) async {
    try {
      await _c.setUserIdentifier(id ?? '');
    } catch (_) {}
  }

  @override
  Future<void> setKey(String key, Object value) async {
    try {
      await _c.setCustomKey(key, value);
    } catch (_) {}
  }

  @override
  Future<void> log(String message) async {
    try {
      await _c.log(message);
    } catch (_) {}
  }
}
