// Signing in to an existing account merges its cloud progress into the
// device. The merge must only ever add: solved stays solved, best times only
// drop, and nothing the device played is lost.

import 'package:drift/drift.dart' show driftRuntimeOptions;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gridwell_flutter_app/data/local/app_database.dart';
import 'package:gridwell_flutter_app/data/local/repositories.dart';

void main() {
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
  late AppDatabase db;
  late ProgressRepository repo;
  final now = DateTime(2026, 11, 3, 12);

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    repo = ProgressRepository(db);
  });
  tearDown(() => db.close());

  Map<String, Object?> row(String id, {bool solved = true, int? best, String? solvedAt}) => {
        'puzzle_id': id,
        'puzzle_set_version': 1,
        'is_solved': solved,
        'best_time_ms': best,
        'solved_at': solvedAt,
        'last_played_at': solvedAt,
        'client_updated_at': solvedAt ?? '2026-11-01T00:00:00Z',
      };

  test('adds plates solved only in the cloud', () async {
    final changed = await repo.mergeRemote([row('a', best: 90000, solvedAt: '2026-10-01T10:00:00Z')], now);
    expect(changed, 1);
    final a = (await repo.all())['a']!;
    expect(a.isSolved, isTrue);
    expect(a.bestTimeMs, 90000);
    expect(a.solvedAt, DateTime.parse('2026-10-01T10:00:00Z').toLocal());
  });

  test('keeps the lower best time and the earlier first solve', () async {
    await repo.recordSolve(puzzleId: 'a', setVersion: 1, timeMs: 60000, hintsUsed: 0, now: now);
    await repo.mergeRemote([row('a', best: 120000, solvedAt: '2026-10-01T10:00:00Z')], now);
    var a = (await repo.all())['a']!;
    expect(a.bestTimeMs, 60000, reason: 'device time was better');
    expect(a.solvedAt, DateTime.parse('2026-10-01T10:00:00Z').toLocal(), reason: 'cloud solve was earlier');
    expect(a.solvedWithoutHints, isTrue);

    await repo.mergeRemote([row('a', best: 30000, solvedAt: '2026-10-01T10:00:00Z')], now);
    a = (await repo.all())['a']!;
    expect(a.bestTimeMs, 30000, reason: 'cloud time is better now');
  });

  test('never unsolves a plate and ignores a time on an unsolved cloud row', () async {
    await repo.recordSolve(puzzleId: 'a', setVersion: 1, timeMs: 60000, hintsUsed: 1, now: now);
    await repo.mergeRemote([row('a', solved: false, best: 10000)], now);
    final a = (await repo.all())['a']!;
    expect(a.isSolved, isTrue);
    expect(a.bestTimeMs, 60000);
  });

  test('a repeat merge changes nothing', () async {
    final rows = [row('a', best: 90000, solvedAt: '2026-10-01T10:00:00Z'), row('b', best: 45000, solvedAt: '2026-10-02T10:00:00Z')];
    expect(await repo.mergeRemote(rows, now), 2);
    expect(await repo.mergeRemote(rows, now), 0);
  });
}
