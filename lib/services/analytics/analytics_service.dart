/// Thin, swappable analytics interface. Event names and parameters follow the
/// plan (puzzle_start, puzzle_complete, puzzle_abandon, ...).
abstract interface class AnalyticsService {
  Future<void> log(String event, [Map<String, Object> params = const {}]);

  /// Sends anything buffered. Called when the app goes to the background.
  Future<void> flush();

  /// Turns collection on or off (the player's choice in Settings > Privacy).
  Future<void> setEnabled(bool enabled);
}

/// Records events in memory. Used in tests and before Firebase is ready.
class MemoryAnalytics implements AnalyticsService {
  final events = <(String, Map<String, Object>)>[];

  @override
  Future<void> log(String event, [Map<String, Object> params = const {}]) async =>
      events.add((event, params));

  @override
  Future<void> flush() async {}

  @override
  Future<void> setEnabled(bool enabled) async {}
}

/// Event names in one place so they cannot drift.
abstract final class AnalyticsEvents {
  static const puzzleStart = 'puzzle_start';
  static const puzzleComplete = 'puzzle_complete';
  static const puzzleAbandon = 'puzzle_abandon';
  static const puzzleOpenNoMove = 'puzzle_open_no_move';
  static const hintUsed = 'hint_used';
  static const undoUsed = 'undo_used';
  static const mistakeMade = 'mistake_made';
  static const collectionComplete = 'collection_complete';
  static const dailyStarted = 'daily_started';
  static const dailyCompleted = 'daily_completed';
  static const adShown = 'ad_shown';
  static const adCompleted = 'ad_completed';
  static const iapViewed = 'iap_viewed';
  static const iapPurchased = 'iap_purchased';
  static const settingsChanged = 'settings_changed';
}
