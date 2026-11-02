// Gridwell content tool.
//
//   dart run tool/gridwell.dart check [file-or-dir ...]   analyze pictures while drawing
//   dart run tool/gridwell.dart nudge <file>               suggest pixel fixes for a rejected picture
//   dart run tool/gridwell.dart bake [--seed N] [--api-seed-dir DIR]
//
// bake writes assets/puzzles/set.bin, content/curve_report.md,
// content/curve_report.csv and content/daily_pool.json, and exits 1 if any
// check fails (the report is still written so problems can be read).

import 'dart:io';

import 'package:gridwell_flutter_app/engine/solver/logic_solver.dart';

import 'content/bake.dart';
import 'content/nudge.dart';
import 'content/plates.dart';

void main(List<String> args) {
  if (args.isEmpty) {
    stderr.writeln('usage: dart run tool/gridwell.dart <check|nudge|bake> ...');
    exit(2);
  }
  switch (args.first) {
    case 'check':
      exit(_check(args.skip(1).toList()));
    case 'nudge':
      exit(_nudge(args.skip(1).toList()));
    case 'bake':
      exit(_bake(args.skip(1).toList()));
    default:
      stderr.writeln('unknown command ${args.first}');
      exit(2);
  }
}

String _groupOf(String path) {
  final parts = path.replaceAll('\\', '/').split('/');
  final i = parts.lastIndexOf('campaign');
  if (i >= 0 && i + 1 < parts.length) return parts[i + 1];
  return 'daily';
}

int _check(List<String> paths) {
  final targets = paths.isEmpty ? ['content'] : paths;
  final files = <File>[];
  for (final t in targets) {
    if (FileSystemEntity.isDirectorySync(t)) {
      files.addAll(Directory(t)
          .listSync(recursive: true)
          .whereType<File>()
          .where((f) => f.path.endsWith('.txt')));
    } else {
      files.add(File(t));
    }
  }
  files.sort((a, b) => a.path.compareTo(b.path));
  final logic = LogicSolver();
  var failures = 0;
  for (final f in files) {
    try {
      final a = analyzePlate(parsePlate(f, group: _groupOf(f.path)), logic);
      final p = a.plate;
      final detail = a.ok
          ? 'score ${a.score!.toStringAsFixed(1)}, passes ${a.metrics!.passes}, '
              'amb ${a.metrics!.maxAmbiguity}, early ${(a.metrics!.earlyForcedRatio * 100).round()}%'
          : a.verdict;
      if (!a.ok) failures++;
      stdout.writeln('${a.ok ? 'ok  ' : 'FAIL'} ${p.id.padRight(34)} ${p.width}x${p.height}  $detail');
      final alt = a.alternative;
      if (alt != null) {
        stdout.writeln('     another solution (+ added, - removed):');
        for (final row in alt) {
          stdout.writeln('       $row');
        }
      }
    } on FormatException catch (e) {
      failures++;
      stdout.writeln('FAIL ${e.message}');
    }
  }
  stdout.writeln('${files.length - failures}/${files.length} ok');
  return failures == 0 ? 0 : 1;
}

int _nudge(List<String> args) {
  if (args.isEmpty) {
    stderr.writeln('usage: nudge <file>');
    return 2;
  }
  final plate = parsePlate(File(args.first), group: _groupOf(args.first));
  final result = nudge(plate);
  if (result.changes.isEmpty) {
    stdout.writeln(result.solved ? 'Already fine.' : 'No single-pixel change helps.');
    return result.solved ? 0 : 1;
  }
  stdout.writeln('${result.solved ? 'Fixed' : 'Improved but not fixed'} with '
      '${result.changes.length} change(s):');
  for (final c in result.changes) {
    stdout.writeln('  $c');
  }
  stdout.writeln();
  result.rows.forEach(stdout.writeln);
  return result.solved ? 0 : 1;
}

int _bake(List<String> args) {
  var seed = defaultSeed;
  String? apiSeedDir;
  for (var i = 0; i < args.length; i++) {
    if (args[i] == '--seed') seed = int.parse(args[++i]);
    if (args[i] == '--api-seed-dir') apiSeedDir = args[++i];
  }
  final result = bake(Directory('content'), seed: seed);
  File('content/curve_report.md').writeAsStringSync(result.report);
  File('content/curve_report.csv').writeAsStringSync(result.csv);
  if (!result.ok) {
    stderr.writeln('${result.errors.length} problem(s); asset not written:');
    result.errors.forEach(stderr.writeln);
    return 1;
  }
  File('assets/puzzles/set.bin')
    ..createSync(recursive: true)
    ..writeAsBytesSync(result.bytes!);
  File('content/daily_pool.json').writeAsStringSync(result.dailyJson!);
  if (apiSeedDir != null) {
    File('$apiSeedDir/daily_pool.json')
      ..createSync(recursive: true)
      ..writeAsStringSync(result.dailyJson!);
  }
  stdout.writeln('Baked ${result.bytes!.length} bytes (seed $seed). Report: content/curve_report.md');
  return 0;
}
