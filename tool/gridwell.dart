// Gridwell content tool.
//
//   dart run tool/gridwell.dart check [file-or-dir ...]   analyze pictures while drawing
//   dart run tool/gridwell.dart nudge <file>               suggest pixel fixes for a rejected picture
//   dart run tool/gridwell.dart curve <collection-id>       order + validate one collection, write nothing
//   dart run tool/gridwell.dart bake [--seed N] [--content DIR] [--api-seed-dir DIR]
//
// bake writes assets/puzzles/set.bin, content/curve_report.md,
// content/curve_report.csv and content/daily_pool.json, and exits 1 if any
// check fails (the report is still written so problems can be read).

import 'dart:io';

import 'package:gridwell_flutter_app/engine/solver/logic_solver.dart';

import 'dart:math';

import 'content/bake.dart';
import 'content/curve.dart';
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
    case 'curve':
      exit(_curve(args.skip(1).toList()));
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

int _curve(List<String> args) {
  if (args.isEmpty) {
    stderr.writeln('usage: curve <collection-id>');
    return 2;
  }
  final id = args.first;
  final dir = Directory('content/campaign/$id');
  if (!dir.existsSync()) {
    stderr.writeln('No such collection folder: ${dir.path}');
    return 2;
  }
  final logic = LogicSolver();
  final analyses = [
    for (final f in dir.listSync().whereType<File>().where((f) => f.path.endsWith('.txt')).toList()
      ..sort((a, b) => a.path.compareTo(b.path)))
      analyzePlate(parsePlate(f, group: id), logic),
  ];
  final rejected = analyses.where((a) => !a.ok).toList();
  for (final a in rejected) {
    stdout.writeln('REJECTED ${a.plate.id}: ${a.verdict}');
  }
  final ordered = orderCollection(analyses.where((a) => a.ok).toList(), Random(defaultSeed));
  for (final o in ordered) {
    final p = o.analysis.plate;
    final label = '${o.plateNumber.toString().padLeft(3)}${o.isBreather ? ' b' : '  '} '
        '${p.name.padRight(24)} ${p.width}x${p.height}';
    stdout.writeln('${label.padRight(40)} ${o.score.toStringAsFixed(1).padLeft(5)} '
        '${'#' * (o.score / 4).round()}');
  }
  final errors = validateCollection(id, ordered);
  for (final e in errors) {
    stdout.writeln('PROBLEM $e');
  }
  stdout.writeln(errors.isEmpty && rejected.isEmpty
      ? 'Curve OK (${ordered.length} plates)'
      : '${errors.length + rejected.length} problem(s)');
  return errors.isEmpty && rejected.isEmpty ? 0 : 1;
}

int _bake(List<String> args) {
  var seed = defaultSeed;
  var contentDir = 'content';
  String? apiSeedDir;
  for (var i = 0; i < args.length; i++) {
    if (args[i] == '--seed') seed = int.parse(args[++i]);
    if (args[i] == '--content') contentDir = args[++i];
    if (args[i] == '--api-seed-dir') apiSeedDir = args[++i];
  }
  // Outputs always land in this repo; --content only changes what is read.
  final result = bake(Directory(contentDir), seed: seed);
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
