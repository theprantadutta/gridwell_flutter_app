// The home tabs (Play, Daily, Gallery) and a collection, in a lived-in book
// and an empty one, at phone and tablet sizes with normal and enlarged text.
// Any overflow fails the test.
//
// Screenshots for a visual pass: SHOTS=<dir> flutter test test/home

import 'dart:async';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:drift/drift.dart' show driftRuntimeOptions;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:gridwell_flutter_app/content/puzzle_set.dart';
import 'package:gridwell_flutter_app/data/local/app_database.dart';
import 'package:gridwell_flutter_app/data/local/daily_repository.dart';
import 'package:gridwell_flutter_app/data/local/repositories.dart';
import 'package:gridwell_flutter_app/data/remote/api_client.dart';
import 'package:gridwell_flutter_app/engine/model/board.dart';
import 'package:gridwell_flutter_app/engine/model/cell_state.dart';
import 'package:gridwell_flutter_app/state/daily.dart';
import 'package:gridwell_flutter_app/state/online.dart';
import 'package:gridwell_flutter_app/state/providers.dart';
import 'package:gridwell_flutter_app/state/settings.dart';
import 'package:gridwell_flutter_app/ui/screens/collection_screen.dart';
import 'package:gridwell_flutter_app/ui/screens/contents_screen.dart';
import 'package:gridwell_flutter_app/ui/screens/daily_screen.dart';
import 'package:gridwell_flutter_app/ui/screens/gallery_screen.dart';
import 'package:gridwell_flutter_app/ui/screens/home_shell.dart';
import 'package:gridwell_flutter_app/ui/theme/gridwell_theme.dart';
import 'package:gridwell_flutter_app/ui/theme/palette.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:material_ui/material_ui.dart' as material_ui;

import '../support/fonts.dart';

final _shotKey = GlobalKey();

const _sizes = <String, Size>{
  'phone-320': Size(320, 640),
  'iphone-390': Size(390, 844),
  'tab-a9-800': Size(800, 1340),
  'tab-a9-land': Size(1340, 800),
};

void main() {
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
  late PuzzleSet set;

  setUpAll(() async {
    await loadTallyFonts();
    set = PuzzleSetCodec.decode(File('assets/puzzles/set.bin').readAsBytesSync());
  });

  test('streak counts runs of days solved on the day', () {
    final d = {for (final n in [1, 2, 3, 5, 6, 7, 8]) DateTime(2026, 11, n)};
    final s = dailyStreakOf(d, DateTime(2026, 11, 9, 10));
    expect(s.current, 4);
    expect(s.best, 4);
    expect(dailyStreakOf(d, DateTime(2026, 11, 8, 23)).current, 4);
    expect(dailyStreakOf(d, DateTime(2026, 11, 10)).current, 0);
    expect(dailyStreakOf(const {}, DateTime(2026, 11, 10)).best, 0);
  });

  final routes = <String, String Function(PuzzleSet)>{
    'contents': (_) => '/contents',
    'daily': (_) => '/daily',
    'gallery': (_) => '/gallery',
    'collection': (s) => '/collection/${s.collections.first.id}',
    'collection-empty': (s) => '/collection/${s.collections[2].id}',
  };

  for (final lived in [true, false]) {
    for (final MapEntry(key: name, value: route) in routes.entries) {
      for (final MapEntry(key: sizeName, value: size) in _sizes.entries) {
        for (final scale in [1.0, 1.3]) {
          for (final dark in [false, true]) {
            if (scale != 1.0 && (dark || sizeName != 'phone-320')) continue;
            testWidgets('$name${lived ? '' : ' (empty)'} @ $sizeName x$scale${dark ? ' dark' : ''}', (tester) async {
              await _pump(tester, set, route(set), name, size, scale, dark, lived);
            });
          }
        }
      }
    }
  }
}

Future<void> _pump(WidgetTester tester, PuzzleSet set, String route, String name, Size size, double scale, bool dark,
    bool lived) async {
  tester.view.physicalSize = size * 2;
  tester.view.devicePixelRatio = 2;
  tester.platformDispatcher.textScaleFactorTestValue = scale;
  addTearDown(tester.view.reset);
  addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);

  final db = AppDatabase(NativeDatabase.memory());
  if (lived) {
    await tester.runAsync(() async {
      final progress = ProgressRepository(db);
      final boards = BoardRepository(db);
      final daily = DailyRepository(db);
      final now = DateTime.now();
      // Most of the first collection, some of the second, a few of the rest.
      for (final (i, c) in set.collections.indexed) {
        final plates = set.inCollection(c.id);
        final take = [14, 20, 0, 9][i % 4];
        for (final x in plates.take(take)) {
          await progress.recordSolve(
              puzzleId: x.id, setVersion: set.puzzleSetVersion, timeMs: 60000 + x.width * 9000, hintsUsed: 0, now: now);
        }
      }
      // A board half done: the next plate in the first collection.
      final next = set.inCollection(set.collections.first.id)[14];
      final cells = [
        for (var i = 0; i < next.solution.cells.length; i++)
          next.solution.cells[i] && i.isEven ? CellState.filled : CellState.empty,
      ];
      await boards.save(
        next.id,
        set.puzzleSetVersion,
        SavedBoard(board: Board(next.width, next.height, cells), elapsedMs: 378000, hintsUsed: 0, moves: 40, setVersion: set.puzzleSetVersion),
        now,
      );
      // A streak of dailies ending yesterday.
      for (var d = 1; d <= 5; d++) {
        final date = localDateString(DateTime(now.year, now.month, now.day - d));
        await daily.recordSolve(date: date, puzzleId: 'daily-$date', timeMs: 300000, onDay: true);
      }
    });
  }

  final container = ProviderContainer(overrides: [
    databaseProvider.overrideWithValue(db),
    puzzleSetProvider.overrideWithValue(set),
    initialSettingsProvider.overrideWithValue(
      Settings(onboardingDone: true, themeMode: dark ? ThemeMode.dark : ThemeMode.light),
    ),
    apiClientProvider.overrideWithValue(ApiClient(
      baseUrl: 'http://localhost/api/v1',
      client: MockClient((_) async => http.Response('{"error":"offline"}', 503)),
    )),
  ]);

  final router = GoRouter(initialLocation: route, routes: [
    ShellRoute(
      builder: (context, state, child) => HomeShell(location: state.uri.path, child: child),
      routes: [
        GoRoute(path: '/contents', builder: (_, _) => const ContentsScreen()),
        GoRoute(path: '/daily', builder: (_, _) => const DailyScreen()),
        GoRoute(path: '/gallery', builder: (_, _) => const GalleryScreen()),
        GoRoute(path: '/settings', builder: (_, _) => const SizedBox()),
      ],
    ),
    GoRoute(path: '/collection/:id', builder: (_, s) => CollectionScreen(collectionId: s.pathParameters['id']!)),
  ]);
  final palette = GridwellPalette.of(dark ? Brightness.dark : Brightness.light);
  await tester.pumpWidget(UncontrolledProviderScope(
    container: container,
    child: MaterialApp.router(
      builder: (context, child) => RepaintBoundary(key: _shotKey, child: child),
      routerConfig: router,
      theme: GridwellTheme.themeData(palette),
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        ...material_ui.GlobalMaterialLocalizations.delegates,
      ],
    ),
  ));
  for (var i = 0; i < 6; i++) {
    await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 5)));
    await tester.pump(const Duration(milliseconds: 400));
  }

  final shots = Platform.environment['SHOTS'];
  if (shots != null && scale == 1.0) {
    final boundary = tester.renderObject<RenderRepaintBoundary>(find.byKey(_shotKey));
    await tester.runAsync(() async {
      final image = await boundary.toImage(pixelRatio: 2);
      final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
      File('$shots/$name${lived ? '' : '-empty'}-${size.width.toInt()}-${dark ? 'dark' : 'light'}.png')
          .writeAsBytesSync(bytes!.buffer.asUint8List());
    });
  }

  // Scroll every scrollable to its end so content below the fold lays out too.
  for (final s in find.byType(Scrollable).evaluate().toList()) {
    final pos = ((s as StatefulElement).state as ScrollableState).position;
    if (pos.hasContentDimensions && pos.maxScrollExtent > 0) pos.jumpTo(pos.maxScrollExtent);
  }
  await tester.pump();

  await tester.pumpWidget(const SizedBox());
  router.dispose();
  container.dispose();
  await tester.pump(const Duration(seconds: 1));
  unawaited(db.close());
  await tester.pump(const Duration(seconds: 1));
}
