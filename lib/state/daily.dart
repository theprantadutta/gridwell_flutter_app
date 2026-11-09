import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../engine/model/puzzle.dart';
import '../services/ads/ad_service.dart';
import 'online.dart';
import 'services.dart';

/// One day on the calendar.
enum DayState { solved, missed, unlocked, today, future, unavailable }

class DailyDay {
  const DailyDay({required this.date, required this.state, this.puzzle, this.timeMs});

  final DateTime date;
  final DayState state;
  final PuzzleRecord? puzzle;
  final int? timeMs;

  String get key => localDateString(date);
}

/// Today's daily. Always available offline from the bundled pool once the
/// calendar has started.
final todayDailyProvider = Provider<PuzzleRecord?>((ref) {
  ref.watch(dailyCacheProvider); // prefer the server copy when it arrives
  return dailyFor(ref, localDateString(DateTime.now()));
});

/// Every day of [month] (first day of month) with its state.
final dailyMonthProvider = Provider.family<List<DailyDay>, DateTime>((ref, month) {
  ref.watch(dailyCacheProvider);
  final results = ref.watch(dailyResultsProvider).value ?? const {};
  final today = DateTime.now();
  final todayKey = localDateString(today);
  final days = DateTime(month.year, month.month + 1, 0).day;
  return [
    for (var d = 1; d <= days; d++)
      () {
        final date = DateTime(month.year, month.month, d);
        final key = localDateString(date);
        final result = results[key];
        final puzzle = dailyFor(ref, key);
        final DayState state;
        if (result?.solved ?? false) {
          state = DayState.solved;
        } else if (key == todayKey) {
          state = DayState.today;
        } else if (key.compareTo(todayKey) > 0) {
          state = DayState.future;
        } else if (puzzle == null) {
          state = DayState.unavailable;
        } else if (result?.unlocked ?? false) {
          state = DayState.unlocked;
        } else {
          state = DayState.missed;
        }
        return DailyDay(date: date, state: state, puzzle: puzzle, timeMs: result?.timeMs);
      }(),
  ];
});

class DailyActions {
  DailyActions(this._ref);

  final Ref _ref;

  /// Unlocks a missed day: free for premium, otherwise one rewarded video.
  /// Returns true if the day can now be played.
  Future<MissedUnlock> unlockMissed(DailyDay day) async {
    final puzzle = day.puzzle;
    if (puzzle == null) return MissedUnlock.failed;
    if (day.state == DayState.unlocked || day.state == DayState.solved || day.state == DayState.today) {
      return MissedUnlock.alreadyOpen;
    }
    var outcome = MissedUnlock.premium;
    if (!_ref.read(entitlementsProvider).premium) {
      final ads = _ref.read(adServiceProvider);
      final grantsBefore = ads.freeGrants;
      final ok = await ads.showRewarded(AdPlacement.missedDaily);
      if (!ok) return MissedUnlock.notWatched;
      outcome = ads.freeGrants > grantsBefore ? MissedUnlock.free : MissedUnlock.watched;
    }
    await _ref.read(dailyRepositoryProvider).unlock(day.key, puzzle.id);
    return outcome;
  }
}

/// How unlocking a missed day went, so the screen can say so.
enum MissedUnlock {
  /// It was already playable.
  alreadyOpen,

  /// Premium: unlocked with no video.
  premium,

  /// Unlocked after a rewarded video.
  watched,

  /// No video could load, so it was unlocked anyway.
  free,

  /// The video was closed before it finished.
  notWatched,
  failed;

  bool get unlocked => this != notWatched && this != failed;
}

final dailyActionsProvider = Provider((ref) => DailyActions(ref));

/// Daily streak: [current] counts consecutive days solved on their own date,
/// ending today (or yesterday while today is still open); [best] is the
/// longest such run ever.
class DailyStreak {
  const DailyStreak({required this.current, required this.best});

  final int current;
  final int best;
}

final dailyStreakProvider = Provider<DailyStreak>((ref) {
  final results = ref.watch(dailyResultsProvider).value ?? const {};
  final days = <DateTime>{
    for (final r in results.values)
      if (r.solved && r.solvedOnDay) ?DateTime.tryParse(r.date),
  };
  return dailyStreakOf(days, DateTime.now());
});

/// Pure streak arithmetic over local calendar days (time of day ignored).
DailyStreak dailyStreakOf(Set<DateTime> solvedDays, DateTime now) {
  final keys = {for (final d in solvedDays) DateTime(d.year, d.month, d.day)};
  final sorted = keys.toList()..sort();
  var best = 0, run = 0;
  DateTime? prev;
  for (final d in sorted) {
    run = prev != null && DateTime(prev.year, prev.month, prev.day + 1) == d ? run + 1 : 1;
    if (run > best) best = run;
    prev = d;
  }
  var day = DateTime(now.year, now.month, now.day);
  if (!keys.contains(day)) day = DateTime(day.year, day.month, day.day - 1);
  var current = 0;
  while (keys.contains(day)) {
    current++;
    day = DateTime(day.year, day.month, day.day - 1);
  }
  return DailyStreak(current: current, best: best);
}
