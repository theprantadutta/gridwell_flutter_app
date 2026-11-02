import '../model/solution.dart';
import '../solver/logic_solver.dart';

/// Raw measurements of how hard a puzzle is to reason through.
class DifficultyMetrics {
  const DifficultyMetrics({
    required this.passes,
    required this.maxAmbiguity,
    required this.earlyForcedRatio,
    required this.density,
    required this.width,
    required this.height,
  });

  /// Measures a line-solvable puzzle from its solve trace.
  factory DifficultyMetrics.measure(Solution solution, SolveTrace trace) {
    if (!trace.isSolved) {
      throw ArgumentError('Difficulty is only defined for line-solvable puzzles');
    }
    final firstPass = trace.newCellsPerPass.isEmpty ? 0 : trace.newCellsPerPass.first;
    return DifficultyMetrics(
      passes: trace.passes,
      maxAmbiguity: trace.maxAmbiguity,
      earlyForcedRatio: firstPass / solution.cellCount,
      density: solution.density,
      width: solution.width,
      height: solution.height,
    );
  }

  /// Full row+column sweeps needed to reach the fixpoint.
  final int passes;

  /// Largest number of unknown cells in one line that still had to be reasoned
  /// about (second pass onward).
  final int maxAmbiguity;

  /// Fraction of all cells determined in the first pass. High means the
  /// puzzle gives a lot away up front.
  final double earlyForcedRatio;

  /// Fraction of cells that are filled.
  final double density;

  final int width;
  final int height;

  int get cellCount => width * height;
}

/// Weights of each component in the difficulty score. They sum to 1.
///
/// Grid size gets the smallest weight on purpose: the curve should be driven
/// by how much reasoning a puzzle takes, not by how big it is. A 20x20 that
/// solves itself must score below a tight 10x10.
abstract final class DifficultyWeights {
  static const passes = 0.35;
  static const earlyGiveaway = 0.25;
  static const ambiguity = 0.20;
  static const density = 0.12;
  static const size = 0.08;
}

/// Each component normalized to 0..1, where 1 is hardest.
class DifficultyComponents {
  const DifficultyComponents({
    required this.passes,
    required this.earlyGiveaway,
    required this.ambiguity,
    required this.density,
    required this.size,
  });

  factory DifficultyComponents.of(DifficultyMetrics m) => DifficultyComponents(
        // One pass is trivial; 11 or more is as interleaved as it gets.
        passes: _clamp01((m.passes - 1) / 10),
        // Little given away in the first sweep makes the start hard.
        earlyGiveaway: _clamp01(1 - m.earlyForcedRatio),
        // 15 or more unknowns in a line that still needed reasoning is the ceiling.
        ambiguity: _clamp01(m.maxAmbiguity / 15),
        // Near 50% fill is hardest; very sparse or very dense is easier.
        density: _clamp01(1 - (m.density - 0.5).abs() * 2),
        // 5x5 is 0, 20x20 is 1.
        size: _clamp01((m.cellCount - 25) / 375),
      );

  final double passes;
  final double earlyGiveaway;
  final double ambiguity;
  final double density;
  final double size;

  static double _clamp01(double v) => v < 0 ? 0 : (v > 1 ? 1 : v);
}

/// Difficulty score from 0 (trivial) to 100 (hardest).
double difficultyScore(DifficultyMetrics m) {
  final c = DifficultyComponents.of(m);
  return 100 *
      (DifficultyWeights.passes * c.passes +
          DifficultyWeights.earlyGiveaway * c.earlyGiveaway +
          DifficultyWeights.ambiguity * c.ambiguity +
          DifficultyWeights.density * c.density +
          DifficultyWeights.size * c.size);
}
