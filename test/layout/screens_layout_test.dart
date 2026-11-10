// Renders every screen at phone and tablet sizes, portrait and landscape, at
// normal and enlarged text, with the real Schibsted Grotesk font. Any overflow or
// layout exception fails the test, so a screen that only fits one device
// cannot ship.
//
// Run: flutter test test/layout

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
import 'package:gridwell_flutter_app/data/local/app_database.dart';
import 'package:gridwell_flutter_app/data/local/repositories.dart';
import 'package:gridwell_flutter_app/data/remote/api_client.dart';
import 'package:gridwell_flutter_app/state/board_controller.dart';
import 'package:gridwell_flutter_app/state/online.dart';
import 'package:gridwell_flutter_app/state/providers.dart';
import 'package:gridwell_flutter_app/state/settings.dart';
import 'package:gridwell_flutter_app/ui/router.dart';
import 'package:gridwell_flutter_app/ui/theme/gridwell_theme.dart';
import 'package:gridwell_flutter_app/ui/theme/palette.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:material_ui/material_ui.dart' as material_ui;

/// Logical sizes: small phone, common phones (the A24 is 384 wide), tablets
/// in both orientations.
const sizes = <String, Size>{
  'phone-320': Size(320, 640),
  'phone-360': Size(360, 760),
  'a24-384': Size(384, 832),
  'phone-412': Size(412, 915),
  'tablet-600': Size(600, 960),
  'tab-a9-800': Size(800, 1340),
  'tab-a9-land': Size(1340, 800),
  'ipad-1024': Size(1024, 1366),
  'ipad-land': Size(1366, 1024),
};

const textScales = [1.0, 1.3];

final _shotKey = GlobalKey();

// Phones are portrait-only (main.dart locks them), so landscape sizes are
// tablet sizes only.

Future<void> _loadFonts() => loadTallyFonts();

void main() {
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
  late PuzzleSet set;

  setUpAll(() async {
    await _loadFonts();
    set = PuzzleSetCodec.decode(File('assets/puzzles/set.bin').readAsBytesSync());
  });

  String plateOfSize(int w) => set.puzzles.firstWhere((p) => p.width == w).id;

  final routes = <String, String Function()>{
    'contents': () => '/contents',
    'daily': () => '/daily',
    'gallery': () => '/gallery',
    'settings': () => '/settings',
    'collection': () => '/collection/${set.collections.first.id}',
    'board-5': () => '/play/${plateOfSize(5)}',
    'board-10': () => '/play/${plateOfSize(10)}',
    'board-15': () => '/play/${plateOfSize(15)}',
    'board-20': () => '/play/${plateOfSize(20)}',
    'complete': () => '/complete',
    'plate': () => '/plate/${set.puzzles.first.id}',
    'store': () => '/store',
    'privacy': () => '/privacy',
    'legal': () => '/legal/terms',
    'account': () => '/account',
    'account-email': () => '/account/email',
    'onboarding': () => '/onboarding',
  };

  for (final MapEntry(key: name, value: route) in routes.entries) {
    for (final MapEntry(key: sizeName, value: size) in sizes.entries) {
      for (final scale in textScales) {
        for (final dark in [false, true]) {
          if (dark && scale != 1.0) continue; // color does not change layout; one dark pass is enough
          testWidgets('$name @ $sizeName x$scale${dark ? ' dark' : ''}', (tester) async {
            await _pumpScreen(tester, set, route(), size, scale, dark);
          });
        }
      }
    }
  }
}

Future<void> _pumpScreen(WidgetTester tester, PuzzleSet set, String route, Size size, double scale, bool dark) async {
  tester.view.physicalSize = size * 3;
  tester.view.devicePixelRatio = 3;
  tester.platformDispatcher.textScaleFactorTestValue = scale;
  addTearDown(tester.view.reset);
  addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);

  final db = AppDatabase(NativeDatabase.memory());
  // A believable book: a few solves, a board in progress.
  await tester.runAsync(() async {
    final progress = ProgressRepository(db);
    final now = DateTime(2026, 11, 3, 12);
    for (final p in set.puzzles.take(4)) {
      await progress.recordSolve(puzzleId: p.id, setVersion: set.puzzleSetVersion, timeMs: 83000, hintsUsed: 0, now: now);
    }
  });

  final first = set.puzzles.first;
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
  container.read(lastCompletionProvider.notifier).set(CompletionResult(
        puzzle: first,
        timeMs: 83000,
        outcome: const SolveOutcome(isFirstSolve: true, isPersonalBest: true, previousBestMs: null),
        hintsUsed: 0,
        sizeBestMs: 95000,
        beatSizeBest: true,
        collectionSolved: 5,
        collectionTotal: 30,
        completedCollection: false,
      ));

  final router = buildRouter(onboardingDone: true)..go(route);
  final palette = GridwellPalette.of(dark ? Brightness.dark : Brightness.light, highContrast: false);
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
  // Let streams deliver and entrance animations finish.
  for (var i = 0; i < 6; i++) {
    await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 5)));
    await tester.pump(const Duration(milliseconds: 700));
  }

  // Scroll every scrollable to its end so content below the fold is laid out too.
  for (final s in Platform.environment['SHOTS'] != null ? const <Element>[] : find.byType(Scrollable).evaluate().toList()) {
    final state = (s as StatefulElement).state as ScrollableState;
    final pos = state.position;
    if (pos.hasContentDimensions && pos.maxScrollExtent > 0) pos.jumpTo(pos.maxScrollExtent);
  }
  await tester.pump();

  // Overflows are reported by the framework with the offending widget and
  // fail the test on their own.

  // Optional screenshots for a visual pass: SHOTS=<dir> flutter test test/layout
  final shots = Platform.environment['SHOTS'];
  if (shots != null && scale == 1.0 && !dark) {
    final boundary = tester.renderObject<RenderRepaintBoundary>(find.byKey(_shotKey));
    await tester.runAsync(() async {
      final image = await boundary.toImage(pixelRatio: 1.5);
      final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
      final safe = '${route.replaceAll(RegExp(r'[^a-z0-9]+'), '_')}_${size.width.toInt()}x${size.height.toInt()}';
      File('$shots/$safe.png').writeAsBytesSync(bytes!.buffer.asUint8List());
    });
  }

  await tester.pumpWidget(const SizedBox());
  router.dispose();
  container.dispose();
  await tester.pump(const Duration(seconds: 1));
  // Close without awaiting inside fake async (drift's close waits on a real
  // event-loop turn); the in-memory database holds nothing worth flushing.
  unawaited(db.close());
  await tester.pump(const Duration(seconds: 1));
}
