// Full pipeline: load -> analyze -> order -> validate -> bake.

import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

import 'package:gridwell_flutter_app/content/puzzle_set.dart';
import 'package:gridwell_flutter_app/engine/model/clues.dart';
import 'package:gridwell_flutter_app/engine/model/puzzle.dart';
import 'package:gridwell_flutter_app/engine/solver/logic_solver.dart';

import 'curve.dart';
import 'plates.dart';

const defaultSeed = 20261102;

class BakeResult {
  BakeResult({
    required this.errors,
    required this.report,
    required this.csv,
    this.bytes,
    this.dailyJson,
  });

  /// Empty when the set passes every check.
  final List<String> errors;

  /// Asset bytes; null when there are errors.
  final Uint8List? bytes;
  final String? dailyJson;
  final String report;
  final String csv;

  bool get ok => errors.isEmpty;
}

/// Runs the pipeline over [contentDir] (expects collections.json,
/// campaign/ and daily/). Pure: writes nothing.
BakeResult bake(Directory contentDir, {int seed = defaultSeed}) {
  final meta = jsonDecode(File('${contentDir.path}/collections.json').readAsStringSync())
      as Map<String, dynamic>;
  final setVersion = meta['puzzle_set_version'] as int;
  final dailyStartDate = meta['daily_start_date'] as String;
  final collections = [
    for (final c in meta['collections'] as List)
      CollectionInfo(
        id: c['id'] as String,
        name: c['name'] as String,
        blurb: c['blurb'] as String,
      ),
  ];

  final loaded = loadAllPlates(contentDir, [for (final c in collections) c.id]);
  final logic = LogicSolver();
  final errors = <String>[];
  final rng = Random(seed);

  // Analyze.
  final campaign = <String, List<PlateAnalysis>>{};
  for (final c in collections) {
    campaign[c.id] = [for (final p in loaded.campaign[c.id]!) analyzePlate(p, logic)];
  }
  final daily = [for (final p in loaded.daily) analyzePlate(p, logic)];

  for (final a in [...campaign.values.expand((x) => x), ...daily]) {
    if (!a.ok) errors.add('${a.plate.id}: ${a.verdict}');
    if (a.plate.source != 'original' && !a.plate.source.startsWith('cc0:')) {
      errors.add('${a.plate.id}: source must be "original" or "cc0:<ref>"');
    }
  }

  // Duplicates (exact solution grids) across everything.
  final seen = <String, String>{};
  for (final a in [...campaign.values.expand((x) => x), ...daily]) {
    final key = '${a.plate.width}x${a.plate.height}:${a.plate.solution.toRows().join('/')}';
    final other = seen[key];
    if (other != null) errors.add('${a.plate.id}: same grid as $other');
    seen[key] = a.plate.id;
  }
  final ids = <String>{};
  for (final a in [...campaign.values.expand((x) => x), ...daily]) {
    if (!ids.add(a.plate.id)) errors.add('${a.plate.id}: duplicate id');
  }

  // Order and validate collections (only plates that passed).
  final ordered = <String, List<OrderedPlate>>{};
  for (final c in collections) {
    final good = campaign[c.id]!.where((a) => a.ok).toList();
    ordered[c.id] = orderCollection(good, rng);
    errors.addAll(validateCollection(c.id, ordered[c.id]!));
  }

  // Daily pool: cap difficulty at the campaign p80.
  final campaignScores = [
    for (final list in ordered.values)
      for (final o in list) o.score,
  ];
  final dailyCap = percentile(campaignScores, CurveRules.dailyMaxPercentile);
  final goodDaily = daily.where((a) => a.ok).toList();
  for (final a in goodDaily) {
    if (campaignScores.isNotEmpty && a.score! > dailyCap) {
      errors.add('${a.plate.id}: daily score ${a.score!.toStringAsFixed(1)} above campaign p80 '
          '${dailyCap.toStringAsFixed(1)}');
    }
  }
  final dailyOrder = [...goodDaily]..sort((a, b) => a.plate.id.compareTo(b.plate.id));
  dailyOrder.shuffle(Random(seed ^ 0x5DA11));

  final report = _report(collections, campaign, ordered, daily, dailyOrder, dailyCap, errors, seed, setVersion);
  final csv = _csv(collections, ordered, dailyOrder);

  if (errors.isNotEmpty) {
    return BakeResult(errors: errors, report: report, csv: csv);
  }

  final puzzles = <PuzzleRecord>[
    for (final c in collections)
      for (final o in ordered[c.id]!)
        PuzzleRecord(
          id: o.analysis.plate.id,
          name: o.analysis.plate.name,
          solution: o.analysis.plate.solution,
          clues: o.analysis.clues,
          difficulty: double.parse(o.score.toStringAsFixed(2)),
          collectionId: c.id,
          plateNumber: o.plateNumber,
          colorLayer: o.analysis.plate.colors,
        ),
  ];
  final set = PuzzleSet(
    puzzleSetVersion: setVersion,
    seed: seed,
    collections: collections,
    puzzles: puzzles,
    dailyStartDate: dailyStartDate,
    dailyPool: [
      for (final a in dailyOrder)
        PuzzleRecord(
          id: a.plate.id,
          name: a.plate.name,
          solution: a.plate.solution,
          clues: a.clues,
          difficulty: double.parse(a.score!.toStringAsFixed(2)),
          collectionId: 'daily',
          plateNumber: 0,
          colorLayer: a.plate.colors,
        ),
    ],
  );
  return BakeResult(
    errors: errors,
    report: report,
    csv: csv,
    bytes: PuzzleSetCodec.encode(set),
    dailyJson: _dailyJson(dailyOrder, seed, dailyStartDate),
  );
}

/// Lowest believable solve time for a player who already knows the answer:
/// at least one drag per run (250 ms each) plus 15 ms per cell to take in
/// the board. Daily leaderboard times below this are rejected.
int minPlausibleMs(Clues clues) {
  var runs = 0;
  for (final row in clues.rows) {
    runs += Clues.blocksOf(row).length;
  }
  final ms = runs * 250 + clues.width * clues.height * 15;
  return (ms / 100).round() * 100;
}

String _dailyJson(List<PlateAnalysis> daily, int seed, String startDate) {
  final encoder = const JsonEncoder.withIndent('  ');
  return '${encoder.convert({
        'seed': seed,
        'start_date': startDate,
        'count': daily.length,
        'puzzles': [
          for (final a in daily)
            {
              'id': a.plate.id,
              'name': a.plate.name,
              'width': a.plate.width,
              'height': a.plate.height,
              'rows': a.plate.rows,
              'row_clues': a.clues.rows,
              'column_clues': a.clues.columns,
              'difficulty': double.parse(a.score!.toStringAsFixed(2)),
              'passes': a.metrics!.passes,
              'min_plausible_ms': minPlausibleMs(a.clues),
            },
        ],
      })}\n';
}

String _fmt(double v) => v.toStringAsFixed(1);

String _report(
  List<CollectionInfo> collections,
  Map<String, List<PlateAnalysis>> campaign,
  Map<String, List<OrderedPlate>> ordered,
  List<PlateAnalysis> daily,
  List<PlateAnalysis> dailyOrder,
  double dailyCap,
  List<String> errors,
  int seed,
  int setVersion,
) {
  final b = StringBuffer()
    ..writeln('# Curve report')
    ..writeln()
    ..writeln('Generated by `dart run tool/gridwell.dart bake`. Do not edit by hand.')
    ..writeln()
    ..writeln('- Puzzle set version: $setVersion')
    ..writeln('- Seed: $seed')
    ..writeln('- Campaign plates: ${ordered.values.fold<int>(0, (n, l) => n + l.length)}'
        ' (of ${campaign.values.fold<int>(0, (n, l) => n + l.length)} drawn)')
    ..writeln('- Daily pool: ${dailyOrder.length} (of ${daily.length} drawn), cap ${_fmt(dailyCap)}')
    ..writeln('- Validation: ${errors.isEmpty ? 'PASS' : 'FAIL (${errors.length})'}')
    ..writeln();

  if (errors.isNotEmpty) {
    b.writeln('## Problems');
    b.writeln();
    for (final e in errors) {
      b.writeln('- $e');
    }
    b.writeln();
  }

  for (final c in collections) {
    final list = ordered[c.id]!;
    b
      ..writeln('## ${c.name} (`${c.id}`), ${list.length} plates')
      ..writeln()
      ..writeln('| # | Plate | Size | Passes | Ambiguity | Early | Density | Score | Curve |')
      ..writeln('|---|---|---|---|---|---|---|---|---|');
    for (final o in list) {
      final m = o.analysis.metrics!;
      final bar = '█' * (o.score / 4).round();
      b.writeln('| ${o.plateNumber}${o.isBreather ? ' (b)' : ''} | ${o.analysis.plate.name} '
          '| ${m.width}x${m.height} | ${m.passes} | ${m.maxAmbiguity} '
          '| ${(m.earlyForcedRatio * 100).round()}% | ${(m.density * 100).round()}% '
          '| ${_fmt(o.score)} | `$bar` |');
    }
    b.writeln();
  }

  b
    ..writeln('## Daily pool (in serving order)')
    ..writeln()
    ..writeln('| Day | Puzzle | Size | Passes | Score | Min ms |')
    ..writeln('|---|---|---|---|---|---|');
  for (var i = 0; i < dailyOrder.length; i++) {
    final a = dailyOrder[i];
    b.writeln('| ${i + 1} | ${a.plate.name} | ${a.plate.width}x${a.plate.height} '
        '| ${a.metrics!.passes} | ${_fmt(a.score!)} | ${minPlausibleMs(a.clues)} |');
  }
  return b.toString();
}

String _csv(
  List<CollectionInfo> collections,
  Map<String, List<OrderedPlate>> ordered,
  List<PlateAnalysis> daily,
) {
  final b = StringBuffer()
    ..writeln('group,plate,id,name,width,height,passes,max_ambiguity,early_forced_ratio,density,score,breather');
  for (final c in collections) {
    for (final o in ordered[c.id]!) {
      final m = o.analysis.metrics!;
      b.writeln('${c.id},${o.plateNumber},${o.analysis.plate.id},"${o.analysis.plate.name}",'
          '${m.width},${m.height},${m.passes},${m.maxAmbiguity},'
          '${m.earlyForcedRatio.toStringAsFixed(3)},${m.density.toStringAsFixed(3)},'
          '${o.score.toStringAsFixed(2)},${o.isBreather}');
    }
  }
  for (var i = 0; i < daily.length; i++) {
    final a = daily[i];
    final m = a.metrics!;
    b.writeln('daily,${i + 1},${a.plate.id},"${a.plate.name}",${m.width},${m.height},'
        '${m.passes},${m.maxAmbiguity},${m.earlyForcedRatio.toStringAsFixed(3)},'
        '${m.density.toStringAsFixed(3)},${a.score!.toStringAsFixed(2)},false');
  }
  return b.toString();
}
