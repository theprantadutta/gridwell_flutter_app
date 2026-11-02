import '../model/clues.dart';

/// What deduction knows about a cell.
enum Knowledge { unknown, filled, empty }

/// Solves a single line: given its clue and the cells already known, returns
/// every cell that is forced.
///
/// A cell is forced filled if it is filled in *every* placement of the clue's
/// runs that agrees with the known cells, and forced empty if it is empty in
/// every such placement. This is the intersection of all valid placements.
///
/// Rather than enumerating placements (exponential on long lines with many
/// short runs), it computes the same intersection with two dynamic programs:
/// which prefixes can hold the first j runs, and which suffixes can hold the
/// rest. That is O(length x runs) per line, so no line can hang the solver and
/// no enumeration cap is needed. `test/engine/line_solver_test.dart` checks it
/// against brute-force enumeration.
///
/// Results are memoized per (clue, line state), since the same lines recur
/// constantly during propagation.
class LineSolver {
  LineSolver({this.memoLimit = 200000});

  /// Memo entries kept before the cache is cleared.
  final int memoLimit;

  final Map<String, List<Knowledge>?> _memo = {};

  int cacheHits = 0;
  int cacheMisses = 0;

  /// Returns the line with every forced cell set, or null if no placement of
  /// [clue] agrees with [line] (a contradiction).
  ///
  /// [clue] uses the display convention (`[0]` for an empty line).
  List<Knowledge>? solve(List<int> clue, List<Knowledge> line) {
    final key = _key(clue, line);
    final cached = _memo[key];
    if (cached != null || _memo.containsKey(key)) {
      cacheHits++;
      return cached;
    }
    cacheMisses++;
    final result = solveLine(Clues.blocksOf(clue), line);
    if (_memo.length >= memoLimit) _memo.clear();
    final stored = result == null ? null : List<Knowledge>.unmodifiable(result);
    _memo[key] = stored;
    return stored;
  }

  static String _key(List<int> clue, List<Knowledge> line) {
    final buffer = StringBuffer()
      ..writeAll(clue, ',')
      ..write('|');
    for (final k in line) {
      buffer.write(k == Knowledge.unknown ? '?' : (k == Knowledge.filled ? '#' : '.'));
    }
    return buffer.toString();
  }
}

/// Uncached line solve. [blocks] are run lengths (empty list for an empty line).
///
/// Returns null on contradiction.
List<Knowledge>? solveLine(List<int> blocks, List<Knowledge> line) {
  final n = line.length;
  final k = blocks.length;

  // emptyBefore[i] = number of known-empty cells in [0, i). Lets us test
  // "no known-empty cell in [a, b)" in O(1).
  final emptyBefore = List<int>.filled(n + 1, 0);
  for (var i = 0; i < n; i++) {
    emptyBefore[i + 1] = emptyBefore[i] + (line[i] == Knowledge.empty ? 1 : 0);
  }
  bool noEmptyIn(int a, int b) => emptyBefore[b] == emptyBefore[a];
  bool canBeEmpty(int i) => line[i] != Knowledge.filled;

  // front[i][j]: cells [0, i) can hold exactly runs 0..j-1.
  final front = List.generate(n + 1, (_) => List<bool>.filled(k + 1, false));
  front[0][0] = true;
  for (var i = 1; i <= n; i++) {
    for (var j = 0; j <= k; j++) {
      // Cell i-1 is a gap.
      var ok = canBeEmpty(i - 1) && front[i - 1][j];
      // Or run j-1 ends exactly at i.
      if (!ok && j > 0) {
        final start = i - blocks[j - 1];
        if (start >= 0 && noEmptyIn(start, i)) {
          ok = start == 0
              ? j == 1
              : canBeEmpty(start - 1) && front[start - 1][j - 1];
        }
      }
      front[i][j] = ok;
    }
  }
  if (!front[n][k]) return null;

  // back[i][j]: cells [i, n) can hold exactly runs j..k-1.
  final back = List.generate(n + 1, (_) => List<bool>.filled(k + 1, false));
  back[n][k] = true;
  for (var i = n - 1; i >= 0; i--) {
    for (var j = k; j >= 0; j--) {
      var ok = canBeEmpty(i) && back[i + 1][j];
      if (!ok && j < k) {
        final end = i + blocks[j];
        if (end <= n && noEmptyIn(i, end)) {
          ok = end == n ? j == k - 1 : canBeEmpty(end) && back[end + 1][j + 1];
        }
      }
      back[i][j] = ok;
    }
  }

  // A cell can be filled if some valid placement of some run covers it.
  // Mark covered ranges with a difference array.
  final coverDelta = List<int>.filled(n + 1, 0);
  for (var j = 0; j < k; j++) {
    final len = blocks[j];
    for (var start = 0; start + len <= n; start++) {
      final end = start + len;
      if (!noEmptyIn(start, end)) continue;
      final prefixOk =
          start == 0 ? j == 0 : canBeEmpty(start - 1) && front[start - 1][j];
      if (!prefixOk) continue;
      final suffixOk =
          end == n ? j == k - 1 : canBeEmpty(end) && back[end + 1][j + 1];
      if (!suffixOk) continue;
      coverDelta[start]++;
      coverDelta[end]--;
    }
  }

  final result = List<Knowledge>.filled(n, Knowledge.unknown);
  var covered = 0;
  for (var i = 0; i < n; i++) {
    covered += coverDelta[i];
    final canFill = covered > 0;
    // A cell can be empty if it sits in a gap between run j-1 and run j.
    var canEmpty = false;
    if (canBeEmpty(i)) {
      for (var j = 0; j <= k && !canEmpty; j++) {
        canEmpty = front[i][j] && back[i + 1][j];
      }
    }
    if (canFill && !canEmpty) {
      result[i] = Knowledge.filled;
    } else if (canEmpty && !canFill) {
      result[i] = Knowledge.empty;
    } else if (!canFill && !canEmpty) {
      return null;
    }
  }
  return result;
}
