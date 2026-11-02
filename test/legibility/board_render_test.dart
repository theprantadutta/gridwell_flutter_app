// Rendered legibility gate: the real board painters draw a 20x20 board at
// phone size, and the measurements are taken from the pixels after each
// color-vision simulation, not from the token values.
//
// PNGs of every variant are written to build/legibility/ for a human look.

import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gridwell_flutter_app/content/puzzle_set.dart';
import 'package:gridwell_flutter_app/engine/model/board.dart';
import 'package:gridwell_flutter_app/engine/model/cell_state.dart';
import 'package:gridwell_flutter_app/engine/rules/rules.dart';
import 'package:gridwell_flutter_app/ui/board/board_geometry.dart';
import 'package:gridwell_flutter_app/ui/board/board_painter.dart';
import 'package:gridwell_flutter_app/ui/theme/palette.dart';

import 'cvd.dart';

const _dpr = 3.0;

/// The narrowest common phone: 360 dp wide, 8 dp margins (the 20x20 layout).
const _available = Size(344, 520);

Future<void> _loadFonts() async {
  final loader = FontLoader('Literata')
    ..addFont(Future.value(ByteData.sublistView(File('assets/fonts/Literata.ttf').readAsBytesSync())));
  await loader.load();
}

class _Rendered {
  _Rendered(this.width, this.height, this.rgba);
  final int width;
  final int height;
  final Uint8List rgba;

  ui.Color at(double x, double y) {
    final px = (x * _dpr).round().clamp(0, width - 1);
    final py = (y * _dpr).round().clamp(0, height - 1);
    final i = (py * width + px) * 4;
    return ui.Color.fromARGB(255, rgba[i], rgba[i + 1], rgba[i + 2]);
  }

  /// The pixel in [r] (logical) with the greatest contrast against [bg].
  ui.Color mostContrasting(ui.Rect r, ui.Color bg, Vision v) {
    var best = bg;
    var bestRatio = 1.0;
    final sbg = simulate(bg, v);
    for (var y = r.top; y < r.bottom; y += 1 / _dpr) {
      for (var x = r.left; x < r.right; x += 1 / _dpr) {
        final c = at(x, y);
        final ratio = contrast(simulate(c, v), sbg);
        if (ratio > bestRatio) {
          bestRatio = ratio;
          best = c;
        }
      }
    }
    return best;
  }
}

void main() {
  late PuzzleSet set;

  setUpAll(() async {
    await _loadFonts();
    set = PuzzleSetCodec.decode(File('assets/puzzles/set.bin').readAsBytesSync());
  });

  final variants = <String, GridwellPalette>{
    'light': GridwellPalette.light,
    'dark': GridwellPalette.dark,
    'light-hc': GridwellPalette.highContrast(GridwellPalette.light),
    'dark-hc': GridwellPalette.highContrast(GridwellPalette.dark),
  };

  for (final MapEntry(key: name, value: palette) in variants.entries) {
    test('20x20 rendered at phone size stays legible: $name', () async {
      final puzzle = set.puzzles.firstWhere((p) => p.id == 'coastline-anchor-large');
      final g = BoardGeometry.fit(puzzle.clues, _available);
      expect(g.cell, greaterThanOrEqualTo(12), reason: 'cells too small to tap');
      expect(g.clueSize, greaterThanOrEqualTo(8), reason: 'clue numbers too small to read');

      // A mid-solve board: the solution's top half filled, its empty cells
      // crossed, the bottom half untouched.
      final cells = <CellState>[];
      for (var i = 0; i < puzzle.solution.cellCount; i++) {
        final r = i ~/ puzzle.width;
        if (r >= 10) {
          cells.add(CellState.empty);
        } else {
          cells.add(puzzle.solution.cells[i] ? CellState.filled : CellState.crossed);
        }
      }
      final board = Board(puzzle.width, puzzle.height, cells);
      final rowRetired = [for (var r = 0; r < 20; r++) retiredClueIndices(puzzle.clues.rows[r], board.row(r))];
      final colRetired = [for (var c = 0; c < 20; c++) retiredClueIndices(puzzle.clues.columns[c], board.column(c))];

      final recorder = ui.PictureRecorder();
      final canvas = ui.Canvas(recorder)..scale(_dpr);
      canvas.drawRect(ui.Offset.zero & g.totalSize, ui.Paint()..color = palette.surface);
      GridPainter(geometry: g, board: board, palette: palette, mistakes: const {}).paint(canvas, g.totalSize);
      CluePainter(
        geometry: g,
        clues: puzzle.clues,
        palette: palette,
        rowRetired: rowRetired,
        colRetired: colRetired,
      ).paint(canvas, g.totalSize);
      final image = await recorder.endRecording().toImage(
        (g.totalSize.width * _dpr).ceil(),
        (g.totalSize.height * _dpr).ceil(),
      );
      final png = await image.toByteData(format: ui.ImageByteFormat.png);
      Directory('build/legibility').createSync(recursive: true);
      File('build/legibility/board-20x20-$name.png').writeAsBytesSync(png!.buffer.asUint8List());
      final raw = await image.toByteData(format: ui.ImageByteFormat.rawRgba);
      final px = _Rendered(image.width, image.height, raw!.buffer.asUint8List());

      // Sample cells by state.
      int? filledI, crossedI, emptyI;
      for (var i = 0; i < cells.length; i++) {
        if (cells[i] == CellState.filled) filledI ??= i;
        if (cells[i] == CellState.crossed) crossedI ??= i;
        if (cells[i] == CellState.empty) emptyI ??= i;
      }
      ui.Rect rect(int i) => g.cellRect(i ~/ 20, i % 20);
      final emptyColor = px.at(rect(emptyI!).center.dx, rect(emptyI).center.dy);
      final filledColor = px.at(rect(filledI!).center.dx, rect(filledI).center.dy);

      // A live clue (bottom rows are untouched) and a retired one (top rows).
      final liveRow = 19, retiredRow = rowRetired.indexWhere((s) => s.isNotEmpty);
      expect(retiredRow, greaterThanOrEqualTo(0));
      ui.Rect clueRect(int r) => ui.Rect.fromLTWH(0, g.colClueHeight + r * g.cell, g.rowClueWidth - g.clueGap * 0.3, g.cell);
      final stripBg = palette.surface;

      for (final v in Vision.values) {
        final filledVsEmpty = contrast(simulate(filledColor, v), simulate(emptyColor, v));
        expect(filledVsEmpty, greaterThanOrEqualTo(7), reason: '$name/${v.name}: filled vs untouched');

        final crossInk = px.mostContrasting(rect(crossedI!).deflate(1), emptyColor, v);
        final crossRatio = contrast(simulate(crossInk, v), simulate(emptyColor, v));
        expect(crossRatio, greaterThanOrEqualTo(3), reason: '$name/${v.name}: cross mark');

        final liveInk = px.mostContrasting(clueRect(liveRow), stripBg, v);
        final liveRatio = contrast(simulate(liveInk, v), simulate(stripBg, v));
        expect(liveRatio, greaterThanOrEqualTo(7), reason: '$name/${v.name}: live clue digits');

        final retiredInk = px.mostContrasting(clueRect(retiredRow), stripBg, v);
        final retiredRatio = contrast(simulate(retiredInk, v), simulate(stripBg, v));
        expect(retiredRatio, greaterThanOrEqualTo(1.8), reason: '$name/${v.name}: retired clue digits');
        expect(liveRatio / retiredRatio, greaterThan(name.endsWith('hc') ? 1.3 : 2),
            reason: '$name/${v.name}: live and retired clues must look different');
      }
    });
  }
}
