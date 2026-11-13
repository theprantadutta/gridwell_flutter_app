// Frame timing on real hardware: a 20x20 board mid drag-paint, the worst case.
//
//   flutter drive --profile -d <device> \
//     --driver=test_driver/perf_driver.dart \
//     --target=integration_test/board_perf_test.dart
//
// Reports average / 90th / 99th percentile build and raster times from the
// engine's FrameTiming data into build/board_perf.json.

import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gridwell_flutter_app/state/providers.dart';
import 'package:gridwell_flutter_app/ui/board/board_geometry.dart';
import 'package:gridwell_flutter_app/ui/board/board_view.dart';
import 'package:gridwell_flutter_app/ui/screens/board_screen.dart';
import 'package:gridwell_flutter_app/ui/theme/gridwell_theme.dart';
import 'package:gridwell_flutter_app/ui/theme/palette.dart';
import 'package:integration_test/integration_test.dart';

const _puzzleId = 'coastline-anchor-large'; // 20x20, the densest board

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  binding.framePolicy = LiveTestWidgetsFlutterBindingFramePolicy.fullyLive;

  testWidgets('20x20 board, sustained drag-paint', (tester) async {
    final overrides = await bootstrapOverrides();
    // Start from an empty board so every stroke paints.
    final container = ProviderContainer(overrides: overrides);
    await container.read(boardRepositoryProvider).delete(_puzzleId);
    final set = container.read(puzzleSetProvider);
    final puzzle = set.puzzles.firstWhere((p) => p.id == _puzzleId);
    container.dispose();

    await tester.pumpWidget(ProviderScope(
      overrides: overrides,
      child: MaterialApp(
        theme: GridwellTheme.themeData(GridwellPalette.light),
        home: const BoardScreen(puzzleId: _puzzleId),
      ),
    ));
    await tester.pumpAndSettle();

    final boardFinder = find.byType(BoardView);
    expect(boardFinder, findsOneWidget);
    final origin = tester.getTopLeft(boardFinder);
    final size = tester.getSize(boardFinder);
    final g = BoardGeometry.fit(puzzle.clues, size);
    // The board is centered inside the view.
    final offset = Offset((size.width - g.totalSize.width) / 2, (size.height - g.totalSize.height) / 2);
    Offset center(int r, int c) => origin + offset + g.cellRect(r, c).center;

    Future<void> stroke(int r0, int c0, int r1, int c1) async {
      final gesture = await tester.startGesture(center(r0, c0));
      const steps = 40;
      for (var i = 1; i <= steps; i++) {
        final t = i / steps;
        final r = r0 + (r1 - r0) * t;
        final c = c0 + (c1 - c0) * t;
        await gesture.moveTo(origin + offset + Offset(g.rowClueWidth + (c + 0.5) * g.cell, g.colClueHeight + (r + 0.5) * g.cell));
        await tester.pump(const Duration(milliseconds: 16));
      }
      await gesture.up();
      await tester.pump(const Duration(milliseconds: 16));
    }

    await binding.watchPerformance(() async {
      // Full-length rows and columns, both directions, fill then erase:
      // about 30 strokes x 40 moves of the heaviest board.
      for (var pass = 0; pass < 2; pass++) {
        for (var r = 0; r < 20; r += 3) {
          await stroke(r, 0, r, 19);
        }
        for (var c = 1; c < 20; c += 3) {
          await stroke(0, c, 19, c);
        }
      }
    }, reportKey: 'board_drag');
  });
}
