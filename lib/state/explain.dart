import '../engine/hints/hint.dart';
import '../engine/hints/proven_mistake.dart';
import '../engine/model/cell_state.dart';
import '../engine/model/clues.dart';
import '../engine/solver/line_solver.dart';

/// Plain-English reasoning for hints and proven mistakes, in the voice of the
/// Folio footnotes ("Row 5 needs one run of 3...").
abstract final class Explain {
  static const _numbers = [
    'zero', 'one', 'two', 'three', 'four', 'five', 'six', 'seven', 'eight', 'nine', 'ten',
  ];

  static String lineName(LineRef line) =>
      '${line.axis == LineAxis.row ? 'Row' : 'Column'} ${line.index + 1}';

  /// What the cell at [position] in [line] is called: rows contain columns.
  static String squareName(LineRef line, int position) =>
      '${line.axis == LineAxis.row ? 'column' : 'row'} ${position + 1}';

  /// "one run of 3", "runs of 2, 1 and 3", "no filled squares".
  static String clueDescription(List<int> clue) {
    final blocks = Clues.blocksOf(clue);
    if (blocks.isEmpty) return 'no filled squares';
    if (blocks.length == 1) return 'one run of ${blocks.first}';
    final head = blocks.sublist(0, blocks.length - 1).join(', ');
    final count = blocks.length < _numbers.length ? _numbers[blocks.length] : '${blocks.length}';
    return '$count runs: $head and ${blocks.last}';
  }

  static String hintTitle(DeducedCellHint h) => lineName(h.line).toUpperCase();

  static String hintBody(DeducedCellHint h) {
    final line = lineName(h.line);
    final square = squareName(h.line, h.position);
    final blank = h.lineBefore.every((k) => k == Knowledge.unknown);
    final needs = '$line needs ${clueDescription(h.clue)}.';
    if (h.value == CellState.filled) {
      return blank
          ? '$needs Pushed as far one way or the other as it goes, it still covers $square.'
          : '$needs With the squares already settled here, every way it can still fit covers $square.';
    }
    return blank
        ? '$needs No way of placing it reaches $square.'
        : '$needs With the squares already settled here, no way it can still fit reaches $square.';
  }

  static String hintConclusion(DeducedCellHint h) {
    final square = squareName(h.line, h.position);
    final cap = square[0].toUpperCase() + square.substring(1);
    return h.value == CellState.filled
        ? 'So $square is filled wherever it sits.'
        : '$cap stays empty.';
  }

  static String wrongMarkBody(WrongMarkHint h) {
    final proof = h.proof;
    if (proof != null) return mistakeBody(proof, filled: null);
    return 'This square does not belong to the picture. Clear it, then carry on.';
  }

  static String mistakeTitle(ProvenMistake m) => lineName(m.line).toUpperCase();

  /// [filled] is whether the mistaken mark is a fill (null: infer from line).
  static String mistakeBody(ProvenMistake m, {required bool? filled}) {
    final line = lineName(m.line);
    final square = squareName(m.line, m.position);
    final needs = '$line has ${clueDescription(m.clue)}.';
    final isFill = filled ?? true;
    return isFill
        ? '$needs With your other marks in it, no way of placing it can reach $square.'
        : '$needs With your other marks in it, every way of placing it fills $square.';
  }
}
