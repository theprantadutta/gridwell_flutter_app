// Plate ordering and curve validation. Rules: docs/CONTENT_PLAN.md.

import 'dart:math';

import 'plates.dart';

abstract final class CurveRules {
  static const gentleStartPlates = 5;
  static const gentleStartMaxScore = 20.0;
  static const earlyWindow = 20;
  static const earlyMaxStep = 10.0;
  static const monotonicTolerance = 4.0;
  static const firstBreather = 10;
  static const breatherEvery = 6;
  static const breatherLookback = 4;
  static const breatherMinDrop = 0.15;
  static const breatherMaxDrop = 0.35;
  static const firstPlateFor15 = 6;
  static const firstPlateFor20 = 12;
  static const dailyMaxPercentile = 0.80;
}

bool isBreatherPosition(int plateNumber) =>
    plateNumber >= CurveRules.firstBreather &&
    (plateNumber - CurveRules.firstBreather) % CurveRules.breatherEvery == 0;

bool sizeAllowedAt(int sizeClass, int plateNumber) => switch (sizeClass) {
      20 => plateNumber >= CurveRules.firstPlateFor20,
      15 => plateNumber >= CurveRules.firstPlateFor15,
      _ => true,
    };

class OrderedPlate {
  OrderedPlate(this.analysis, this.plateNumber, this.isBreather);

  final PlateAnalysis analysis;
  final int plateNumber;
  final bool isBreather;

  double get score => analysis.score!;
}

/// Orders one collection's plates (all must be [PlateAnalysis.ok]).
///
/// Non-breather positions take the easiest remaining plate the size gate
/// allows. Breather positions take the remaining plate closest to the middle
/// of the breather window, chosen from plates held back for that purpose.
/// [rng] only breaks exact ties, so the order is reproducible for a seed.
List<OrderedPlate> orderCollection(List<PlateAnalysis> plates, Random rng) {
  // Sort by score, then id; shuffle within exact-score ties by seed.
  final pool = [...plates]..sort((a, b) {
      final c = a.score!.compareTo(b.score!);
      return c != 0 ? c : a.plate.id.compareTo(b.plate.id);
    });
  final tieKeys = {for (final p in pool) p.plate.id: rng.nextInt(1 << 30)};
  pool.sort((a, b) {
    final c = a.score!.compareTo(b.score!);
    return c != 0 ? c : tieKeys[a.plate.id]!.compareTo(tieKeys[b.plate.id]!);
  });

  final n = pool.length;
  final breatherPositions = [
    for (var p = 1; p <= n; p++)
      if (isBreatherPosition(p)) p,
  ];

  // Reserve breathers: for each breather slot, estimate the mean of the four
  // plates before it as the scores at the matching ranks of the
  // non-reserved pool, then hold back the plate nearest 75% of that mean.
  final reserved = <PlateAnalysis>{};
  for (final pos in breatherPositions) {
    final normal = pool.where((p) => !reserved.contains(p)).toList();
    final before = <double>[];
    var normalIndex = 0;
    for (var p = 1; p < pos && normalIndex < normal.length; p++) {
      if (isBreatherPosition(p)) continue;
      before.add(normal[normalIndex++].score!);
    }
    if (before.length < CurveRules.breatherLookback) continue;
    final mean = before.sublist(before.length - CurveRules.breatherLookback).reduce((a, b) => a + b) /
        CurveRules.breatherLookback;
    final target = mean * (1 - (CurveRules.breatherMinDrop + CurveRules.breatherMaxDrop) / 2);
    // A breather is easier than the plates before it, so candidates come from
    // anywhere in the remaining pool. Holding one back shifts later plates
    // forward by one, which the final pass re-checks against the real window.
    final candidates = normal.where((p) {
      final s = p.score!;
      return s >= mean * (1 - CurveRules.breatherMaxDrop) &&
          s <= mean * (1 - CurveRules.breatherMinDrop) &&
          sizeAllowedAt(p.plate.sizeClass, pos);
    }).toList();
    if (candidates.isEmpty) continue;
    candidates.sort((a, b) => (a.score! - target).abs().compareTo((b.score! - target).abs()));
    reserved.add(candidates.first);
  }

  // Repair: build, find the first breather outside its real window, swap in
  // the plate that best fits that window, and rebuild. Bounded, so it always
  // terminates; anything still wrong is reported by the validator.
  var ordered = _build(pool, reserved);
  final unfixable = <int>{};
  for (var iteration = 0; iteration < 200; iteration++) {
    final miss = _breatherMisses(ordered).where((m) => !unfixable.contains(m.$1)).firstOrNull;
    if (miss == null) break;
    final (slot, lo, hi) = miss;
    final target = (lo + hi) / 2;
    final current = ordered[slot - 1];
    final candidates = pool.where((p) {
      if (reserved.contains(p)) return false;
      final s = p.score!;
      return s >= lo && s <= hi && sizeAllowedAt(p.plate.sizeClass, slot);
    }).toList()
      ..sort((a, b) => (a.score! - target).abs().compareTo((b.score! - target).abs()));
    if (candidates.isEmpty) {
      unfixable.add(slot);
      continue;
    }
    if (current.isBreather) reserved.remove(current.analysis);
    reserved.add(candidates.first);
    final rebuilt = _build(pool, reserved);
    // Keep the swap only if it does not increase the number of misses.
    if (_breatherMisses(rebuilt).length > _breatherMisses(ordered).length) {
      reserved.remove(candidates.first);
      if (current.isBreather) reserved.add(current.analysis);
      unfixable.add(slot);
      continue;
    }
    ordered = rebuilt;
  }
  return ordered;
}

/// Lays out [pool] with [reserved] plates on breather slots.
List<OrderedPlate> _build(List<PlateAnalysis> pool, Set<PlateAnalysis> reserved) {
  final n = pool.length;
  final normalQueue = pool.where((p) => !reserved.contains(p)).toList();
  final breatherQueue = reserved.toList()..sort((a, b) => b.score!.compareTo(a.score!));
  final out = <OrderedPlate>[];
  for (var pos = 1; pos <= n; pos++) {
    if (isBreatherPosition(pos) && breatherQueue.isNotEmpty) {
      final prev = out.where((o) => !o.isBreather).map((o) => o.score).toList();
      final look = prev.length >= CurveRules.breatherLookback
          ? prev.sublist(prev.length - CurveRules.breatherLookback)
          : prev;
      final mean = look.isEmpty ? 0.0 : look.reduce((a, b) => a + b) / look.length;
      final target = mean * (1 - (CurveRules.breatherMinDrop + CurveRules.breatherMaxDrop) / 2);
      breatherQueue.sort((a, b) => (a.score! - target).abs().compareTo((b.score! - target).abs()));
      out.add(OrderedPlate(breatherQueue.removeAt(0), pos, true));
      continue;
    }
    final source = normalQueue.isNotEmpty ? normalQueue : breatherQueue;
    var index = source.indexWhere((p) => sizeAllowedAt(p.plate.sizeClass, pos));
    if (index < 0) index = 0; // Gate impossible to meet; the validator reports it.
    out.add(OrderedPlate(source.removeAt(index), pos, false));
  }
  return out;
}

/// Breather slots whose plate is missing or outside its window, as
/// (slot, low, high).
List<(int, double, double)> _breatherMisses(List<OrderedPlate> ordered) {
  final misses = <(int, double, double)>[];
  final normal = <double>[];
  for (final o in ordered) {
    if (isBreatherPosition(o.plateNumber)) {
      if (normal.length >= CurveRules.breatherLookback) {
        final look = normal.sublist(normal.length - CurveRules.breatherLookback);
        final mean = look.reduce((a, b) => a + b) / look.length;
        final lo = mean * (1 - CurveRules.breatherMaxDrop);
        final hi = mean * (1 - CurveRules.breatherMinDrop);
        if (!o.isBreather || o.score < lo || o.score > hi) misses.add((o.plateNumber, lo, hi));
      }
      continue;
    }
    normal.add(o.score);
  }
  return misses;
}

/// Checks one ordered collection against the curve rules.
List<String> validateCollection(String id, List<OrderedPlate> ordered) {
  final errors = <String>[];
  void fail(OrderedPlate o, String msg) =>
      errors.add('$id #${o.plateNumber} ${o.analysis.plate.id} (${o.score.toStringAsFixed(1)}): $msg');

  var runningMax = 0.0;
  final normalScores = <double>[];
  for (var i = 0; i < ordered.length; i++) {
    final o = ordered[i];
    final pos = o.plateNumber;
    if (pos <= CurveRules.gentleStartPlates && o.score > CurveRules.gentleStartMaxScore) {
      fail(o, 'gentle start: score above ${CurveRules.gentleStartMaxScore}');
    }
    // Early cliffs are measured against the previous non-breather plate: the
    // climb back from a breather to the curve is not a cliff.
    if (pos <= CurveRules.earlyWindow && !isBreatherPosition(pos) && normalScores.isNotEmpty) {
      final step = o.score - normalScores.last;
      if (step > CurveRules.earlyMaxStep) {
        fail(o, 'early cliff: +${step.toStringAsFixed(1)} over the previous plate on the curve');
      }
    }
    if (!sizeAllowedAt(o.analysis.plate.sizeClass, pos)) {
      fail(o, 'size gate: ${o.analysis.plate.sizeClass}x class too early');
    }
    if (isBreatherPosition(pos)) {
      if (!o.isBreather) {
        fail(o, 'no breather available for this slot');
      } else if (normalScores.length >= CurveRules.breatherLookback) {
        final look = normalScores.sublist(normalScores.length - CurveRules.breatherLookback);
        final mean = look.reduce((a, b) => a + b) / look.length;
        final lo = mean * (1 - CurveRules.breatherMaxDrop);
        final hi = mean * (1 - CurveRules.breatherMinDrop);
        if (o.score < lo || o.score > hi) {
          fail(o, 'breather outside window ${lo.toStringAsFixed(1)}..${hi.toStringAsFixed(1)}');
        }
      }
      continue;
    }
    if (o.score < runningMax - CurveRules.monotonicTolerance) {
      fail(o, 'drops below running max ${runningMax.toStringAsFixed(1)} by more than ${CurveRules.monotonicTolerance}');
    }
    runningMax = max(runningMax, o.score);
    normalScores.add(o.score);
  }
  return errors;
}

/// Score at [percentile] (0..1) of [scores].
double percentile(List<double> scores, double percentile) {
  final sorted = [...scores]..sort();
  if (sorted.isEmpty) return 0;
  final index = ((sorted.length - 1) * percentile).round();
  return sorted[index];
}
