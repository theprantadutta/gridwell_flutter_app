// The board must not move when anything around it appears, and the first-game
// walkthrough must reach every control and hand the clock back at the end.
//
// Run: flutter test test/layout/board_stability_test.dart

import 'dart:async';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:drift/drift.dart' show driftRuntimeOptions;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gridwell_flutter_app/content/puzzle_set.dart';
import 'package:gridwell_flutter_app/data/local/app_database.dart';
import 'package:gridwell_flutter_app/data/remote/api_client.dart';
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
    final image = await boundary.toImage(pixelRatio: 1.5);
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
    File('$dir/$name.png').writeAsBytesSync(bytes!.buffer.asUint8List());
  });
}

void main() {
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
  late PuzzleSet set;

  setUpAll(() async {
    Future<ByteData> read(String path) async =>
        ByteData.sublistView(File(path).readAsBytesSync());
    await (FontLoader('Literata')
          ..addFont(read('assets/fonts/Literata.ttf'))
          ..addFont(read('assets/fonts/Literata-Italic.ttf')))
        .load();
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
            themeMode: ThemeMode.light,
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
            GridwellPalette.of(Brightness.light, highContrast: false),
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
      expect(find.text('Got it'), findsOneWidget);
      await shot(tester, 'dock-$name-1-note');
      expect(tester.getRect(view), before, reason: 'hint note moved the board');
      expect(
        tester.getRect(find.text('Undo')),
        controls,
        reason: 'the hint note moved the controls',
      );

      await tester.tap(find.text('Got it'));
      await settle(tester);
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
      final origin =
          view.topLeft +
          Offset(
            (view.width - g.totalSize.width) / 2,
            (view.height - g.totalSize.height) / 2,
          );
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
        'Fill or Cross',
        'Row and column',
        'Undo',
        'Hint',
      ]) {
        await shot(tester, 'tour-$name-${title.split(' ').first}');
        expect(find.text(title), findsWidgets);
        await tester.tap(find.text('Next'));
        await settle(tester);
      }
      expect(find.text('Your time'), findsOneWidget);
      await shot(tester, 'tour-$name-time');
      await tester.tap(find.text('Start solving'));
      await settle(tester);
      expect(find.byType(BoardTour), findsNothing);
      expect(container.read(settingsProvider).boardTourDone, isTrue);

      await tester.pumpWidget(const SizedBox());
      await tester.pump(const Duration(seconds: 1));
    });
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
