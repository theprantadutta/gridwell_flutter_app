import 'dart:async';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'online.dart';
import 'providers.dart';

/// Debug-only: gives a TEST account a believable solved book, for store
/// screenshots and for checking screens that look empty on a fresh install.
///
///     flutter run -d <device> --dart-define=GW_SEED=true --dart-define=API_ENV=prod
///
/// It never runs in a release or profile build: [kDebugMode] is a compile-time
/// constant, so the body is tree-shaken out of anything that ships, and the
/// define has to be passed deliberately on top of that.
///
/// Rules, so it cannot pollute a real account by accident:
///  * It waits for a signed-in, non-guest account and seeds nothing without one.
///  * It runs once per install. `GW_SEED_FORCE=true` runs it again.
///  * `GW_SEED_PLATES` changes how many plates each collection gets (default 8).
///
/// For screenshots without ads, also give the account premium:
/// `dotnet run grant-premium-to-user.cs -- grant <email>` in the API repo.
class DevDataSeeder {
  DevDataSeeder(this._ref);

  final Ref _ref;

  static const _requested = bool.fromEnvironment('GW_SEED');
  static const _force = bool.fromEnvironment('GW_SEED_FORCE');
  static const _plates = int.fromEnvironment('GW_SEED_PLATES', defaultValue: 8);
  static const _doneKey = 'debug_dev_data_seeded_v1';

  Future<void> runIfRequested() async {
    if (!kDebugMode || !_requested) return;
    final settings = _ref.read(settingsRepositoryProvider);
    if (!_force && (await settings.all())[_doneKey] == 'true') return;

    // The cached sign-in can resolve after the first frame: wait for it.
    final auth = _ref.read(authServiceProvider);
    for (var i = 0; auth.current.isGuest; i++) {
      if (i == 30) {
        debugPrint('DevDataSeeder: no signed-in account, skipping');
        return;
      }
      await Future<void>.delayed(const Duration(seconds: 1));
    }

    // Marked first: a crash mid-seed must not loop on every launch.
    final now = DateTime.now();
    await settings.put(_doneKey, 'true', now);

    final set = _ref.read(puzzleSetProvider);
    final progress = _ref.read(progressRepositoryProvider);
    final random = Random(20261104);
    var solved = 0;
    for (final collection in set.collections) {
      for (final p in set.inCollection(collection.id).take(_plates)) {
        // About a second per cell, with some spread, spaced over past days.
        final timeMs = (p.width * p.height * (700 + random.nextInt(900))).clamp(5000, 3600000);
        await progress.recordSolve(
          puzzleId: p.id,
          setVersion: set.puzzleSetVersion,
          timeMs: timeMs,
          hintsUsed: random.nextInt(4) == 0 ? 1 : 0,
          now: now.subtract(Duration(hours: 6 * (set.puzzles.length - solved))),
        );
        solved++;
      }
    }
    await _ref.read(onlineSessionProvider).uploadAllProgress();
    debugPrint('DevDataSeeder: seeded $solved plates');
  }
}

final devDataSeederProvider = Provider((ref) => DevDataSeeder(ref));
