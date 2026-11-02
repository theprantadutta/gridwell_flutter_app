import 'clues.dart';
import 'solution.dart';

/// A shipped puzzle: the picture, its clues, and its place in the book.
class PuzzleRecord {
  PuzzleRecord({
    required this.id,
    required this.name,
    required this.solution,
    required this.clues,
    required this.difficulty,
    required this.collectionId,
    required this.plateNumber,
    this.colorLayer,
  }) {
    final colors = colorLayer;
    if (colors != null && colors.length != solution.cellCount) {
      throw ArgumentError('colorLayer must have one entry per cell');
    }
  }

  /// Stable identifier, unique within a puzzle set version.
  final String id;
  final String name;
  final Solution solution;
  final Clues clues;

  /// Difficulty score, 0..100 (see engine/difficulty).
  final double difficulty;
  final String collectionId;

  /// 1-based position within its collection.
  final int plateNumber;

  /// Palette index per cell for the revealed picture (0 = background).
  /// Null when the picture is shown in ink only.
  final List<int>? colorLayer;

  int get width => solution.width;
  int get height => solution.height;
}
