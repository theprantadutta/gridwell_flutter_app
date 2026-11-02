// Reading picture files and analyzing them with the engine.

import 'dart:convert';
import 'dart:io';

import 'package:gridwell_flutter_app/content/puzzle_set.dart';
import 'package:gridwell_flutter_app/engine/difficulty/difficulty.dart';
import 'package:gridwell_flutter_app/engine/model/clues.dart';
import 'package:gridwell_flutter_app/engine/model/solution.dart';
import 'package:gridwell_flutter_app/engine/solver/logic_solver.dart';
import 'package:gridwell_flutter_app/engine/solver/uniqueness.dart';

/// Grid character -> picture color index.
const colorChars = <String, int>{
  '.': PictureColor.background,
  'k': PictureColor.ink,
  'r': PictureColor.red,
  'o': PictureColor.ochre,
  's': PictureColor.stone,
  'i': PictureColor.indigo,
};

String charForColor(int color) =>
    colorChars.entries.firstWhere((e) => e.value == color).key;

/// One picture file.
class Plate {
  Plate({
    required this.id,
    required this.group,
    required this.name,
    required this.source,
    required this.path,
    required this.rows,
  }) {
    final w = rows.first.length;
    colors = [
      for (final row in rows)
        for (var i = 0; i < w; i++) colorChars[row[i]]!,
    ];
    solution = Solution(w, rows.length, [for (final c in colors) c != 0]);
  }

  /// `<collection>-<slug>` or `daily-<slug>`.
  final String id;

  /// Collection id, or `daily`.
  final String group;
  final String name;
  final String source;
  final String path;
  final List<String> rows;
  late final List<int> colors;
  late final Solution solution;

  int get width => solution.width;
  int get height => solution.height;

  /// 5, 10, 15 or 20, from the longer side.
  int get sizeClass {
    final longest = width > height ? width : height;
    if (longest <= 5) return 5;
    if (longest <= 10) return 10;
    if (longest <= 15) return 15;
    return 20;
  }
}

/// Parses a picture file. Throws [FormatException] with the path on error.
Plate parsePlate(File file, {required String group}) {
  final path = file.path.replaceAll('\\', '/');
  final slug = path.split('/').last.replaceAll('.txt', '');
  final lines = const LineSplitter().convert(file.readAsStringSync());
  final header = <String, String>{};
  var i = 0;
  for (; i < lines.length; i++) {
    final line = lines[i].trim();
    if (line == '---') {
      i++;
      break;
    }
    if (line.isEmpty || line.startsWith('#')) continue;
    final colon = line.indexOf(':');
    if (colon < 0) throw FormatException('$path: bad header line "$line"');
    header[line.substring(0, colon).trim()] = line.substring(colon + 1).trim();
  }
  final rows = [
    for (; i < lines.length; i++)
      if (lines[i].trim().isNotEmpty) lines[i].trim(),
  ];
  if (rows.isEmpty) throw FormatException('$path: no grid');
  final width = rows.first.length;
  for (final row in rows) {
    if (row.length != width) throw FormatException('$path: ragged row "$row"');
    for (final ch in row.split('')) {
      if (!colorChars.containsKey(ch)) {
        throw FormatException('$path: unknown grid character "$ch"');
      }
    }
  }
  final name = header['name'];
  final source = header['source'];
  if (name == null || name.isEmpty) throw FormatException('$path: missing name');
  if (source == null || source.isEmpty) throw FormatException('$path: missing source');
  return Plate(
    id: '$group-$slug',
    group: group,
    name: name,
    source: source,
    path: path,
    rows: rows,
  );
}

/// Engine verdict for one plate.
class PlateAnalysis {
  PlateAnalysis(this.plate, this.clues, this.trace, this.uniqueness)
      : metrics = trace.isSolved ? DifficultyMetrics.measure(plate.solution, trace) : null {
    final m = metrics;
    score = m == null ? null : difficultyScore(m);
  }

  final Plate plate;
  final Clues clues;
  final SolveTrace trace;
  final UniquenessResult uniqueness;
  final DifficultyMetrics? metrics;
  late final double? score;

  bool get lineSolvable => trace.isSolved;
  bool get unique => uniqueness.isUnique;
  bool get ok => lineSolvable && unique;

  /// For a picture with several solutions: a second one, as text rows, with
  /// cells that differ from the drawing shown as `+` (added) and `-` (removed).
  List<String>? get alternative {
    final other = uniqueness.solutions.where((rows) {
      for (var r = 0; r < plate.height; r++) {
        for (var c = 0; c < plate.width; c++) {
          if (((rows[r] >> c) & 1 == 1) != plate.solution.at(r, c)) return true;
        }
      }
      return false;
    }).firstOrNull;
    if (other == null) return null;
    return [
      for (var r = 0; r < plate.height; r++)
        [
          for (var c = 0; c < plate.width; c++)
            switch (((other[r] >> c) & 1 == 1, plate.solution.at(r, c))) {
              (true, false) => '+',
              (false, true) => '-',
              (true, true) => '#',
              _ => '.',
            },
        ].join(),
    ];
  }

  String get verdict {
    if (ok) return 'ok';
    if (!uniqueness.complete) return 'REJECT: oracle incomplete';
    if (uniqueness.count >= 2) return 'REJECT: multiple solutions';
    if (!lineSolvable) {
      final unknown = trace.grid.where((k) => k.name == 'unknown').length;
      return 'REJECT: needs guessing ($unknown cells undecided)';
    }
    return 'REJECT';
  }
}

PlateAnalysis analyzePlate(Plate plate, LogicSolver logic) {
  final clues = Clues.fromSolution(plate.solution);
  final trace = logic.solve(clues);
  // Only line-solvable plates can ship; skip the costly count for the rest,
  // except when it is cheap to tell the author whether it is even unique.
  final uniqueness = trace.isSolved
      ? countSolutions(clues)
      : countSolutions(clues, maxNodes: 200000, collect: true);
  return PlateAnalysis(plate, clues, trace, uniqueness);
}

/// Loads every plate under `content/campaign/<collection>/` and content/daily/.
({Map<String, List<Plate>> campaign, List<Plate> daily}) loadAllPlates(
  Directory contentDir,
  List<String> collectionIds,
) {
  List<Plate> load(Directory dir, String group) {
    if (!dir.existsSync()) return [];
    final files = dir
        .listSync()
        .whereType<File>()
        .where((f) => f.path.endsWith('.txt'))
        .toList()
      ..sort((a, b) => a.path.compareTo(b.path));
    return [for (final f in files) parsePlate(f, group: group)];
  }

  return (
    campaign: {
      for (final id in collectionIds)
        id: load(Directory('${contentDir.path}/campaign/$id'), id),
    },
    daily: load(Directory('${contentDir.path}/daily'), 'daily'),
  );
}
