/// Thin, swappable crash and error reporting.
///
/// Fatal errors are hooked up in main(); this is for the rest: errors the app
/// catches and survives (a failed purchase, an unexpected sign-in failure),
/// plus context that makes any report readable (who, which screen, which
/// puzzle). Never pass personal data: ids are the pseudonymous Firebase uid.
abstract interface class CrashReporter {
  /// Records a caught error as non-fatal.
  Future<void> recordError(Object error, StackTrace? stack, {String? reason});

  /// The pseudonymous user id (Firebase uid), or null to clear it.
  Future<void> setUserId(String? id);

  /// A key shown on every report from now on: screen, puzzle, entitlement.
  Future<void> setKey(String key, Object value);

  /// A breadcrumb line attached to the next report.
  Future<void> log(String message);
}

/// Does nothing. Debug and profile builds, tests, and before Firebase is ready.
class NoopCrashReporter implements CrashReporter {
  const NoopCrashReporter();

  @override
  Future<void> recordError(Object error, StackTrace? stack, {String? reason}) async {}

  @override
  Future<void> setUserId(String? id) async {}

  @override
  Future<void> setKey(String key, Object value) async {}

  @override
  Future<void> log(String message) async {}
}

/// The reporter services use for caught errors. main() swaps in the Firebase
/// one for release builds; everything else sees the no-op.
abstract final class CrashReports {
  static CrashReporter instance = const NoopCrashReporter();
}
