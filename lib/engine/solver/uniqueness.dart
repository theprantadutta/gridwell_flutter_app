import '../model/clues.dart';

/// Result of counting solutions.
class UniquenessResult {
  const UniquenessResult(
    this.count, {
    required this.complete,
    required this.nodes,
    this.solutions = const [],
  });

  /// Solutions found, as row bitmasks (bit c = column c), when requested
  /// with `collect: true`. Used by authoring tools to show an alternative.
  final List<List<int>> solutions;

  /// Solutions found, up to the requested limit.
  final int count;

  /// False if the search hit its node budget before finishing. An incomplete
  /// result proves nothing and must be treated as a failure.
  final bool complete;

  /// Search nodes visited.
  final int nodes;

  bool get isUnique => complete && count == 1;

  @override
  String toString() =>
      'UniquenessResult(count: $count, complete: $complete, nodes: $nodes)';
}

/// Counts solutions to [clues] by backtracking, stopping at [limit].
///
/// This is deliberately a second, independent implementation that shares no
/// code with the line solver. It works from the problem's definition:
///
/// 1. Enumerate every bit pattern that satisfies each row clue and each
///    column clue.
/// 2. Repeatedly pick the unassigned row with the fewest patterns still
///    compatible with the surviving column patterns, and try each one.
/// 3. Assigning a row filters every column's pattern list to those that agree
///    with it at that row. An empty list is a dead end.
///
/// When every row is assigned, every column list agrees with every row, so the
/// grid is a solution. If this and the line solver ever disagree, one of them
/// has a bug, and the test suite fails.
///
/// Lines are bitmasks, so sizes up to 60 are accepted, though pattern counts
/// grow quickly past 25.
UniquenessResult countSolutions(
  Clues clues, {
  int limit = 2,
  int maxNodes = 5000000,
  bool collect = false,
}) {
  final w = clues.width;
  final h = clues.height;
  if (w > 60 || h > 60) {
    throw ArgumentError('Size ${w}x$h exceeds the supported 60');
  }

  final rowPatterns = [
    for (var r = 0; r < h; r++) patternsFor(Clues.blocksOf(clues.rows[r]), w),
  ];
  final colPatterns = [
    for (var c = 0; c < w; c++) patternsFor(Clues.blocksOf(clues.columns[c]), h),
  ];
  if (rowPatterns.any((p) => p.isEmpty) || colPatterns.any((p) => p.isEmpty)) {
    return const UniquenessResult(0, complete: true, nodes: 0);
  }

  var count = 0;
  var nodes = 0;
  var aborted = false;
  final assigned = List<bool>.filled(h, false);
  final chosen = List<int>.filled(h, 0);
  final found = <List<int>>[];

  void search(List<List<int>> cols, int remaining) {
    if (count >= limit || aborted) return;
    if (remaining == 0) {
      count++;
      if (collect) found.add(List<int>.unmodifiable(chosen));
      return;
    }

    // Per column: rows that can be filled (OR of patterns) and rows that must
    // be filled (AND of patterns).
    final canFill = List<int>.filled(w, 0);
    final mustFill = List<int>.filled(w, 0);
    for (var c = 0; c < w; c++) {
      var orMask = 0;
      var andMask = -1;
      for (final p in cols[c]) {
        orMask |= p;
        andMask &= p;
      }
      canFill[c] = orMask;
      mustFill[c] = andMask;
    }

    // Choose the unassigned row with the fewest compatible patterns.
    var bestRow = -1;
    List<int>? bestCandidates;
    for (var r = 0; r < h; r++) {
      if (assigned[r]) continue;
      var fillable = 0; // Columns where row r may be filled.
      var forced = 0; // Columns where row r must be filled.
      for (var c = 0; c < w; c++) {
        if ((canFill[c] >> r) & 1 == 1) fillable |= 1 << c;
        if ((mustFill[c] >> r) & 1 == 1) forced |= 1 << c;
      }
      final candidates = <int>[
        for (final p in rowPatterns[r])
          if (p & ~fillable == 0 && p & forced == forced) p,
      ];
      if (candidates.isEmpty) return; // Dead end.
      if (bestCandidates == null || candidates.length < bestCandidates.length) {
        bestRow = r;
        bestCandidates = candidates;
        if (candidates.length == 1) break;
      }
    }

    assigned[bestRow] = true;
    for (final pattern in bestCandidates!) {
      if (++nodes > maxNodes) {
        aborted = true;
        break;
      }
      chosen[bestRow] = pattern;
      final next = <List<int>>[];
      var dead = false;
      for (var c = 0; c < w && !dead; c++) {
        final bit = (pattern >> c) & 1;
        final kept = <int>[
          for (final p in cols[c])
            if ((p >> bestRow) & 1 == bit) p,
        ];
        if (kept.isEmpty) dead = true;
        next.add(kept);
      }
      if (!dead) search(next, remaining - 1);
      if (count >= limit || aborted) break;
    }
    assigned[bestRow] = false;
  }

  search(colPatterns, h);
  return UniquenessResult(count, complete: !aborted, nodes: nodes, solutions: found);
}

/// Every bitmask of [length] cells whose runs are exactly [blocks]
/// (bit i = cell i). An empty [blocks] gives the single all-empty pattern.
List<int> patternsFor(List<int> blocks, int length) {
  final out = <int>[];
  final suffixNeed = List<int>.filled(blocks.length + 1, 0);
  for (var j = blocks.length - 1; j >= 0; j--) {
    suffixNeed[j] = blocks[j] + suffixNeed[j + 1] + (j < blocks.length - 1 ? 1 : 0);
  }

  void place(int block, int start, int mask) {
    if (block == blocks.length) {
      out.add(mask);
      return;
    }
    final len = blocks[block];
    final run = (1 << len) - 1;
    for (var s = start; s + suffixNeed[block] <= length; s++) {
      place(block + 1, s + len + 1, mask | (run << s));
    }
  }

  place(0, 0, 0);
  return out;
}
