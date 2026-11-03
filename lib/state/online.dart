import 'dart:async';
import 'dart:convert';

import 'package:drift/drift.dart' show Value;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/local/app_database.dart';
import '../data/local/daily_repository.dart';
import '../data/remote/api_client.dart';
import '../engine/model/puzzle.dart';
import '../services/auth/auth_service.dart';
import 'providers.dart';
import 'services.dart';

final apiClientProvider = Provider((ref) => ApiClient());
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

  /// App start and resume: refresh dailies and push anything queued.
  Future<void> onForeground() async {
    await refreshDailies();
    await flushOutbox();
  }
}

final onlineSessionProvider = Provider((ref) => OnlineSession(ref));
