import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;

import '../content/puzzle_set.dart';
import '../data/local/app_database.dart';
import '../data/local/repositories.dart';
import 'settings.dart';

// Row types the UI reads (plain data). Re-exported so ui/ depends on state/
// only, never on data/.
export '../data/local/app_database.dart' show BoardSave, PuzzleProgressData;

/// Overridden in main() with the opened database.
final databaseProvider = Provider<AppDatabase>((ref) => throw UnimplementedError());

/// Overridden in main() with settings read before the first frame, so the
/// theme never flashes.
final initialSettingsProvider = Provider<Settings>((ref) => const Settings());

/// Overridden in main() with the decoded puzzle set (it is small and loads in
/// a few milliseconds, so the first screen can read it synchronously).
final puzzleSetProvider = Provider<PuzzleSet>((ref) => throw UnimplementedError());

final progressRepositoryProvider =
    Provider((ref) => ProgressRepository(ref.watch(databaseProvider)));
final boardRepositoryProvider = Provider((ref) => BoardRepository(ref.watch(databaseProvider)));
final settingsRepositoryProvider =
    Provider((ref) => SettingsRepository(ref.watch(databaseProvider)));

/// Every puzzle's progress, keyed by puzzle id.
final progressProvider = StreamProvider<Map<String, PuzzleProgressData>>(
  (ref) => ref.watch(progressRepositoryProvider).watchAll(),
);

/// Boards in progress, most recent first.
final inProgressProvider = StreamProvider<List<BoardSave>>(
  (ref) => ref.watch(boardRepositoryProvider).watchInProgress(),
);

Future<PuzzleSet> loadPuzzleSet() async {
  final data = await rootBundle.load('assets/puzzles/set.bin');
  return PuzzleSetCodec.decode(data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes));
}

/// Bootstrap values needed before the first frame.
Future<List<Override>> bootstrapOverrides() async {
  final db = AppDatabase();
  final settings = Settings.fromMap(await SettingsRepository(db).all());
  final set = await loadPuzzleSet();
  return [
    databaseProvider.overrideWithValue(db),
    initialSettingsProvider.overrideWithValue(settings),
    puzzleSetProvider.overrideWithValue(set),
  ];
}
