// The board must not move when anything around it appears, and the first-game
// walkthrough must reach every control and hand the clock back at the end.
//
// Run: flutter test test/layout/board_stability_test.dart

import 'dart:async';
import 'dart:io';
import 'dart:ui' as ui;

import '../support/fonts.dart';
import 'package:drift/drift.dart' show driftRuntimeOptions;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gridwell_flutter_app/content/puzzle_set.dart';
import 'package:gridwell_flutter_app/engine/model/cell_state.dart';
import 'package:gridwell_flutter_app/data/local/app_database.dart';
import 'package:gridwell_flutter_app/data/remote/api_client.dart';
import 'package:gridwell_flutter_app/state/board_controller.dart';
import 'package:gridwell_flutter_app/state/online.dart';
import 'package:gridwell_flutter_app/state/providers.dart';
import 'package:gridwell_flutter_app/state/settings.dart';
import 'package:gridwell_flutter_app/ui/board/board_geometry.dart';
import 'package:gridwell_flutter_app/ui/board/board_tour.dart';
import 'package:gridwell_flutter_app/ui/board/board_view.dart';
import 'package:gridwell_flutter_app/ui/router.dart';
import 'package:gridwell_flutter_app/ui/theme/gridwell_theme.dart';
import 'package:gridwell_flutter_app/ui/theme/palette.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:material_ui/material_ui.dart' as material_ui;

const sizes = <String, Size>{
  'phone-320': Size(320, 640),
  'a24-384': Size(384, 832),
  'tab-a9-800': Size(800, 1340),
  'tab-a9-land': Size(1340, 800),
};

final _shotKey = GlobalKey();

/// Optional picture for a visual pass: `SHOTS=dir flutter test test/layout`
Future<void> shot(WidgetTester tester, String name) async {
  final dir = Platform.environment['SHOTS'];
  if (dir == null) return;
  final boundary = tester.renderObject<RenderRepaintBoundary>(
    find.byKey(_shotKey),
  );
  await tester.runAsync(() async {
    final image = await boundary.toImage(pixelRatio: 2);
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
    File('$dir/$name.png').writeAsBytesSync(bytes!.buffer.asUint8List());
  });
}

void main() {
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
  late PuzzleSet set;

  setUpAll(() async {
    await loadTallyFonts();
    set = PuzzleSetCodec.decode(
      File('assets/puzzles/set.bin').readAsBytesSync(),
    );
  });

  Future<ProviderContainer> pumpBoard(
    WidgetTester tester,
    Size size, {
    required bool tourDone,
    int width = 5,
    bool mistakes = true,
    bool dark = false,
    bool autoCross = true,
  }) async {
    tester.view.physicalSize = size * 3;
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    final db = AppDatabase(NativeDatabase.memory());
    final container = ProviderContainer(
      overrides: [
        databaseProvider.overrideWithValue(db),
        puzzleSetProvider.overrideWithValue(set),
        initialSettingsProvider.overrideWithValue(
          Settings(
            onboardingDone: true,
            boardTourDone: tourDone,
            showProvenMistakes: mistakes,
            autoCross: autoCross,
            themeMode: dark ? ThemeMode.dark : ThemeMode.light,
          ),
        ),
        apiClientProvider.overrideWithValue(
          ApiClient(
            baseUrl: 'http://localhost/api/v1',
            client: MockClient(
              (_) async => http.Response('{"error":"offline"}', 503),
            ),
          ),
        ),
      ],
    );
    final puzzle = set.puzzles.firstWhere((p) => p.width == width);
    final router = buildRouter(onboardingDone: true)..go('/play/${puzzle.id}');
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp.router(
          builder: (context, child) =>
              RepaintBoundary(key: _shotKey, child: child),
          routerConfig: router,
          theme: GridwellTheme.themeData(
            GridwellPalette.of(dark ? Brightness.dark : Brightness.light, highContrast: false),
          ),
          localizationsDelegates: const [
            GlobalMaterialLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            ...material_ui.GlobalMaterialLocalizations.delegates,
          ],
        ),
      ),
    );
    await settle(tester);
    addTearDown(() async {
      router.dispose();
      container.dispose();
      unawaited(db.close());
    });
    return container;
  }

  for (final MapEntry(key: name, value: size) in sizes.entries) {
    testWidgets('board stays put through a hint and a tap @ $name', (
      tester,
    ) async {
      await pumpBoard(tester, size, tourDone: true);
      final view = find.byType(BoardView);
      final before = tester.getRect(view);
      final controls = tester.getRect(find.text('Undo'));
      await shot(tester, 'dock-$name-0');

      await tester.tap(find.text('Hint'));
      await settle(tester);
      expect(find.text('APPLY'), findsOneWidget);
      await shot(tester, 'dock-$name-1-note');
      expect(tester.getRect(view), before, reason: 'hint note moved the board');
      expect(
        tester.getRect(find.text('Undo')),
        controls,
        reason: 'the hint note moved the controls',
      );

      await tester.tap(find.text('APPLY'));
      await settle(tester);
      expect(find.text('APPLY'), findsNothing);
      expect(
        tester.getRect(view),
        before,
        reason: 'closing the note moved the board',
      );

      await tester.tapAt(before.center);
      await settle(tester);
      await shot(tester, 'dock-$name-2-cell');
      expect(
        tester.getRect(view),
        before,
        reason: 'the clue readout moved the board',
      );

      await tester.pumpWidget(const SizedBox());
      await tester.pump(const Duration(seconds: 1));
    });

    testWidgets('clue readout holds still across rows @ $name', (tester) async {
      // Random taps would raise mistake notes; this test is about the readout.
      await pumpBoard(tester, size, tourDone: true, width: 20, mistakes: false);
      final view = tester.getRect(find.byType(BoardView));
      final controls = tester.getRect(find.text('Undo'));
      Rect? label;
      // Down the left edge of the grid, then across the bottom: every row and
      // column has a different clue length.
      // Where the grid sits, worked out the way BoardView lays it out.
      final puzzle = set.puzzles.firstWhere((p) => p.width == 20);
      final g = BoardGeometry.fit(puzzle.clues, view.size);
      final origin = view.topLeft + g.originIn(view.size, center: size.width >= 840 && size.width > size.height * 1.15);
      for (final i in [2, 6, 9, 13, 17]) {
        await tester.tapAt(origin + g.cellRect(i, 19).center);
        await settle(tester);
        await tester.tapAt(origin + g.cellRect(19, i).center);
        await settle(tester);
        final l = tester.getRect(find.textContaining('ROW ').first);
        label ??= l;
        expect(l.top, label.top, reason: 'the ROW label moved');
        expect(
          tester.getRect(find.text('Undo')),
          controls,
          reason: 'the controls moved',
        );
        expect(
          tester.getRect(find.byType(BoardView)),
          view,
          reason: 'the board moved',
        );
      }
      await shot(tester, 'readout-$name-20');

      await tester.pumpWidget(const SizedBox());
      await tester.pump(const Duration(seconds: 1));
    });

    testWidgets('walkthrough reaches every step @ $name', (tester) async {
      final container = await pumpBoard(tester, size, tourDone: false);
      expect(find.byType(BoardTour), findsOneWidget);
      for (final title in [
        'The clues',
        'The grid',
        'Fill or mark',
        'Undo',
        'Hint',
      ]) {
        await shot(tester, 'tour-$name-${title.split(' ').first}');
        expect(find.text(title), findsWidgets);
        await tester.tap(find.text('NEXT'));
        await settle(tester);
      }
      expect(find.text('Your time'), findsOneWidget);
      await shot(tester, 'tour-$name-time');
      await tester.tap(find.text('START SOLVING'));
      await settle(tester);
      expect(find.byType(BoardTour), findsNothing);
      expect(container.read(settingsProvider).boardTourDone, isTrue);

      await tester.pumpWidget(const SizedBox());
      await tester.pump(const Duration(seconds: 1));
    });
  }

  testWidgets('a hint is spent when shown; CLOSE leaves the board, APPLY places it', (tester) async {
    final container = await pumpBoard(tester, sizes['a24-384']!, tourDone: true);
    final puzzle = set.puzzles.firstWhere((p) => p.width == 5);
    BoardSession session() => container.read(boardControllerProvider(puzzle.id));
    final board0 = session().board;

    await tester.tap(find.text('Hint'));
    await settle(tester);
    expect(session().hintsUsed, 1);
    expect(find.text('APPLY'), findsOneWidget);
    await tester.tap(find.text('CLOSE'));
    await settle(tester);
    expect(find.text('APPLY'), findsNothing);
    expect(session().board, same(board0), reason: 'CLOSE must not place the hint');
    expect(session().hintsUsed, 1, reason: 'a closed hint stays spent');

    await tester.tap(find.text('Hint'));
    await settle(tester);
    expect(session().hintsUsed, 2);
    final note = session().note!;
    await tester.tap(find.text('APPLY'));
    await settle(tester);
    expect(session().board.at(note.row, note.col), note.result);
    expect(session().hintsUsed, 2, reason: 'APPLY does not spend a second hint');

    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(seconds: 1));
  });

  // A visual pass against the kit: SHOTS=dir flutter test test/layout/board_stability_test.dart
  for (final dark in [false, true]) {
    final theme = dark ? 'dark' : 'light';
    for (final width in [5, 15, 20]) {
      testWidgets('kit look: $width×$width board, hint and mistake ($theme)', (tester) async {
        final container = await pumpBoard(tester, const Size(390, 844), tourDone: true, width: width, dark: dark, autoCross: false);
        final puzzle = set.puzzles.firstWhere((p) => p.width == width);
        final controller = container.read(boardControllerProvider(puzzle.id).notifier);
        // A few correct fills and dashes so the board looks mid-solve.
        final sol = puzzle.solution;
        // Only correct fills: a wrong one can complete a line, and auto-cross
        // would then dash squares that belong to the picture.
        for (var i = 0; i < sol.cellCount * 0.55; i += 2) {
          if (!sol.cells[i]) continue;
          controller.strokeStart(i ~/ sol.width, i % sol.width);
          controller.strokeEnd();
        }
        controller.setMode(InputMode.cross);
        for (var i = 1; i < sol.cellCount; i += 3) {
          if (!sol.cells[i]) {
            controller.strokeStart(i ~/ sol.width, i % sol.width);
            controller.strokeEnd();
          }
        }
        controller.setMode(InputMode.fill);
        controller.strokeStart(sol.height ~/ 2, sol.width ~/ 2 + 1);
        controller.strokeEnd();
        await settle(tester);
        await shot(tester, 'kit-$width-$theme-0-board');

        await tester.tap(find.text('Hint'));
        await settle(tester);
        await shot(tester, 'kit-$width-$theme-1-hint');
        await tester.tap(find.text('CLOSE'));
        await settle(tester);

        // A filled square the clues rule out: a gap in a row whose runs are all
        // filled. (Auto-cross is off here, so the gap is never dashed.)
        CellState at(int r, int c) => container.read(boardControllerProvider(puzzle.id)).board.at(r, c);
        final row = List.generate(sol.height, (r) => r)
            .firstWhere((r) => List.generate(sol.width, (c) => sol.cells[r * sol.width + c]).contains(false));
        final gap = List.generate(sol.width, (c) => c).firstWhere((c) => !sol.cells[row * sol.width + c]);
        for (var c = 0; c < sol.width; c++) {
          if (sol.cells[row * sol.width + c] && at(row, c) != CellState.filled) {
            controller.strokeStart(row, c);
            controller.strokeEnd();
          }
        }
        if (at(row, gap) == CellState.crossed) {
          controller.setMode(InputMode.cross);
          controller.strokeStart(row, gap);
          controller.strokeEnd();
          controller.setMode(InputMode.fill);
        }
        controller.strokeStart(row, gap);
        controller.strokeEnd();
        await settle(tester);
        expect(container.read(boardControllerProvider(puzzle.id)).note?.kind, BoardNoteKind.mistake);
        await shot(tester, 'kit-$width-$theme-2-mistake');

        await tester.pumpWidget(const SizedBox());
        await tester.pump(const Duration(seconds: 1));
      });
    }
  }
}

Future<void> settle(WidgetTester tester) async {
  for (var i = 0; i < 6; i++) {
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 5)),
    );
    await tester.pump(const Duration(milliseconds: 300));
  }
}
