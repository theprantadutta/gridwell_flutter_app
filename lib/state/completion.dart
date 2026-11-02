import '../content/puzzle_set.dart';
import '../data/local/app_database.dart';
import '../engine/model/puzzle.dart';

/// The plate after [current]: the next one in its collection, or the first
/// unsolved plate of a later collection, or null at the end of the book.
PuzzleRecord? nextPuzzleAfter(
  PuzzleSet set,
  Map<String, PuzzleProgressData> progress,
  PuzzleRecord current,
) {
  final inCollection = set.inCollection(current.collectionId);
  final i = inCollection.indexWhere((p) => p.id == current.id);
  if (i >= 0 && i + 1 < inCollection.length) return inCollection[i + 1];
  final ci = set.collections.indexWhere((c) => c.id == current.collectionId);
  for (var k = 1; k <= set.collections.length; k++) {
    final c = set.collections[(ci + k) % set.collections.length];
    final unsolved = set.inCollection(c.id).where((p) => !(progress[p.id]?.isSolved ?? false));
    if (unsolved.isNotEmpty) return unsolved.first;
  }
  return null;
}
