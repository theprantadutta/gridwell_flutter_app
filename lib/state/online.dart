import 'dart:async';
import 'dart:convert';

import 'package:drift/drift.dart' show Value;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/local/app_database.dart';
import '../data/local/daily_repository.dart';
import '../data/remote/api_client.dart';
import '../engine/model/puzzle.dart';
import '../services/auth/auth_service.dart';
import '../services/config/app_env.dart';
import 'providers.dart';
import 'services.dart';
import 'settings.dart';

final apiClientProvider = Provider((ref) => ApiClient(baseUrl: AppEnv.apiBaseUrl));
final authServiceProvider = Provider((ref) => AuthService());
final dailyRepositoryProvider = Provider((ref) => DailyRepository(ref.watch(databaseProvider)));

/// Cached dailies, keyed by local date (yyyy-MM-dd).
final dailyCacheProvider = StreamProvider<Map<String, Map<String, Object?>>>(
  (ref) => ref.watch(dailyRepositoryProvider).watchCache(),
);

/// What happened on each daily, keyed by date.
final dailyResultsProvider = StreamProvider<Map<String, DailyResult>>(
  (ref) => ref.watch(dailyRepositoryProvider).watchResults(),
);

/// Pen name from the server, once signed in.
class PenName extends Notifier<String?> {
  @override
  String? build() => null;
  void set(String? v) => state = v;
}

final penNameProvider = NotifierProvider<PenName, String?>(PenName.new);

String localDateString(DateTime d) =>
    '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

int get tzOffsetMinutes => DateTime.now().timeZoneOffset.inMinutes;

/// Puzzle key for a day's daily: each day is its own puzzle (own saved
/// board, own result), even when the bundled pool wraps around.
String dailyKey(DateTime date) => 'daily@${localDateString(date)}';

/// Local date a daily key belongs to, or null for book plates.
String? dailyDateOfKey(String id) => id.startsWith('daily@') ? id.substring(6) : null;

/// The daily for [date]: the server's copy if cached, otherwise the pool
/// bundled in the app (day N after the shared start date is puzzle N). This
/// is what makes the daily work with no connection at all.
PuzzleRecord? dailyFor(Ref ref, String date) {
  final cache = ref.read(dailyCacheProvider).value ?? const {};
  final cached = cache[date];
  final base = cached != null ? DailyRepository.recordFromJson(cached) : _bundledDaily(ref, date);
  if (base == null) return null;
  return PuzzleRecord(
    id: 'daily@$date',
    name: base.name,
    solution: base.solution,
    clues: base.clues,
    difficulty: base.difficulty,
    collectionId: DailyRepository.collectionId,
    plateNumber: 0,
    colorLayer: base.colorLayer,
  );
}

PuzzleRecord? _bundledDaily(Ref ref, String date) {
  final set = ref.read(puzzleSetProvider);
  final start = DateTime.tryParse(set.dailyStartDate);
  final day = DateTime.tryParse(date);
  if (start == null || day == null || set.dailyPool.isEmpty) return null;
  final n = DateTime.utc(day.year, day.month, day.day).difference(DateTime.utc(start.year, start.month, start.day)).inDays;
  if (n < 0) return null;
  return set.dailyPool[n % set.dailyPool.length];
}

/// Resolves any playable puzzle key: book plates from the baked set, dailies
/// via [dailyFor].
PuzzleRecord? resolvePuzzle(Ref ref, String id) {
  final date = dailyDateOfKey(id);
  if (date != null) return dailyFor(ref, date);
  for (final p in ref.read(puzzleSetProvider).puzzles) {
    if (p.id == id) return p;
  }
  return null;
}

/// Everything that talks to the server: sign-in, daily refresh, sync. All
/// best-effort and silent; nothing here blocks play.
class OnlineSession {
  OnlineSession(this._ref);

  final Ref _ref;
  Future<bool>? _signingIn;

  ApiClient get _api => _ref.read(apiClientProvider);

  Future<bool> ensureSignedIn() {
    if (_api.token != null) return Future.value(true);
    return _signingIn ??= () async {
      try {
        final idToken = await _ref.read(authServiceProvider).idToken();
        if (idToken == null) return false;
        final user = await _api.authWithFirebase(idToken, tzOffsetMinutes);
        if (user == null) return false;
        _ref.read(penNameProvider.notifier).set(user['pen_name'] as String?);
        final ent = user['entitlements'] as Map<String, Object?>?;
        if (ent != null) applyEntitlements(ent);
        return true;
      } finally {
        _signingIn = null;
      }
    }();
  }

  void applyEntitlements(Map<String, Object?> e) {
    final premium = (e['premium'] as Map<String, Object?>?)?['active'] == true;
    _ref.read(entitlementsProvider.notifier).set(Entitlements(
          removeAds: e['remove_ads'] == true,
          premium: premium,
        ));
  }

  /// Caches today's daily and the next six, plus this month's past days.
  Future<void> refreshDailies() async {
    if (!await ensureSignedIn()) return;
    final now = DateTime.now();
    final repo = _ref.read(dailyRepositoryProvider);
    final upcoming = await _api.upcomingDailies(localDateString(now), tzOffsetMinutes);
    if (upcoming != null) await repo.cache(upcoming, now);
    final monthStart = DateTime(now.year, now.month, 1);
    final past = await _api.dailyRange(localDateString(monthStart), localDateString(now));
    if (past != null) await repo.cache(past, now);
  }

  /// Pushes queued changes. The server acknowledges every row, accepted or
  /// rejected, and every acknowledged row leaves the outbox, so nothing
  /// retries in a loop.
  Future<void> flushOutbox() async {
    final db = _ref.read(databaseProvider);
    final rows = await db.select(db.outbox).get();
    if (rows.isEmpty || !await ensureSignedIn()) return;

    final progress = <String, Map<String, Object?>>{};
    Map<String, Object?>? settings;
    final dailyCompletions = <OutboxData>[];
    for (final r in rows) {
      final payload = jsonDecode(r.payload) as Map<String, Object?>;
      switch (r.kind) {
        case 'progress':
          progress[payload['puzzle_id'] as String] = payload; // latest wins locally
        case 'settings':
          settings = payload;
        case 'daily_complete':
          dailyCompletions.add(r);
      }
    }

    final syncIds = rows.where((r) => r.kind != 'daily_complete').map((r) => r.id).toList();
    if (progress.isNotEmpty || settings != null) {
      final ack = await _api.syncPush({
        'progress': progress.values.toList(),
        'settings': ?settings,
      });
      if (ack != null) {
        await (db.delete(db.outbox)..where((t) => t.id.isIn(syncIds))).go();
      }
    }
    for (final r in dailyCompletions) {
      final p = jsonDecode(r.payload) as Map<String, Object?>;
      final ack = await _api.completeDaily(p['date'] as String, p['time_ms'] as int, p['client_local_date'] as String);
      if (ack != null) await (db.delete(db.outbox)..where((t) => t.id.equals(r.id))).go();
    }
  }

  Future<void> enqueue(String kind, Map<String, Object?> payload) async {
    final db = _ref.read(databaseProvider);
    await db.into(db.outbox).insert(OutboxCompanion.insert(
          kind: kind,
          payload: jsonEncode(payload),
          createdAt: DateTime.now(),
          attempts: const Value(0),
        ));
    unawaited(flushOutbox());
  }

  /// Forgets the server session after the Firebase identity changed, so the
  /// next call signs in again as the new account.
  void resetSession() {
    _api.token = null;
    _signingIn = null;
    _ref.read(penNameProvider.notifier).set(null);
  }

  /// Pulls the account's cloud progress and merges it into this device.
  /// Returns the number of plates that changed, or null when offline.
  Future<int?> restoreFromCloud() async {
    if (!await ensureSignedIn()) return null;
    final snapshot = await _api.syncPull();
    if (snapshot == null) return null;
    final rows = (snapshot['progress'] as List?)?.whereType<Map<String, Object?>>().toList() ?? const [];
    final changed = await _ref.read(progressRepositoryProvider).mergeRemote(rows, DateTime.now());
    final ent = snapshot['entitlements'] as Map<String, Object?>?;
    if (ent != null) applyEntitlements(ent);
    final values = (snapshot['settings'] as Map<String, Object?>?)?['values'];
    if (values is Map<String, Object?>) await _ref.read(settingsProvider.notifier).applyRemote(values);
    return changed;
  }

  /// Queues every solve on this device for upload, so a guest's progress
  /// lands in the account they just signed in to.
  Future<void> uploadAllProgress() async {
    final rows = await _ref.read(progressRepositoryProvider).all();
    final db = _ref.read(databaseProvider);
    final now = DateTime.now();
    await db.batch((b) {
      for (final r in rows.values.where((r) => r.isSolved && dailyDateOfKey(r.puzzleId) == null)) {
        b.insert(db.outbox, OutboxCompanion.insert(
          kind: 'progress',
          payload: jsonEncode({
            'puzzle_id': r.puzzleId,
            'puzzle_set_version': r.setVersion,
            'is_solved': true,
            'best_time_ms': r.bestTimeMs,
            'solved_at': (r.solvedAt ?? now).toUtc().toIso8601String(),
            'last_played_at': (r.lastPlayedAt ?? now).toUtc().toIso8601String(),
            'client_updated_at': r.updatedAt.toUtc().toIso8601String(),
          }),
          createdAt: now,
          attempts: const Value(0),
        ));
      }
    });
    await flushOutbox();
  }

  /// App start and resume: refresh dailies and push anything queued.
  Future<void> onForeground() async {
    await refreshDailies();
    await flushOutbox();
  }
}

final onlineSessionProvider = Provider((ref) => OnlineSession(ref));

/// One leaderboard row.
class LeaderboardEntry {
  const LeaderboardEntry(this.rank, this.penName, this.timeMs, this.isYou);
  final int rank;
  final String penName;
  final int timeMs;
  final bool isYou;
}

class DailyLeaderboard {
  const DailyLeaderboard(this.total, this.entries, this.you);
  final int total;
  final List<LeaderboardEntry> entries;
  final LeaderboardEntry? you;
}

/// The day's leaderboard, or null when offline. Waits for any queued
/// completion to be pushed first, so your own time is included.
final dailyLeaderboardProvider = FutureProvider.family<DailyLeaderboard?, String>((ref, date) async {
  final online = ref.read(onlineSessionProvider);
  await online.flushOutbox();
  if (!await online.ensureSignedIn()) return null;
  final j = await ref.read(apiClientProvider).dailyLeaderboard(date, limit: 5);
  if (j == null) return null;
  LeaderboardEntry entry(Map<String, Object?> e) => LeaderboardEntry(
        e['rank'] as int,
        e['pen_name'] as String,
        e['time_ms'] as int,
        e['is_current_user'] == true,
      );
  final you = j['current_user'];
  return DailyLeaderboard(
    j['total_entries'] as int? ?? 0,
    [for (final e in (j['entries'] as List? ?? const [])) entry(e as Map<String, Object?>)],
    you is Map<String, Object?> ? entry(you) : null,
  );
});

extension PenNameActions on OnlineSession {
  /// Renames the pen name on the server. Returns an error message, or null.
  Future<String?> rename(String name) async {
    if (!await ensureSignedIn()) return 'You need a connection to change your pen name.';
    final res = await _ref.read(apiClientProvider).updateProfile(penName: name.trim());
    if (res == null) return 'That name could not be used. Try another.';
    _ref.read(penNameProvider.notifier).set(res['pen_name'] as String? ?? name.trim());
    return null;
  }
}
