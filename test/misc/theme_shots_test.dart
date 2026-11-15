// Renders the main screens in every theme at the A24's size, so a theme can be
// judged on real screens, not just its swatches. Writes PNGs only when
// SHOTS=<dir> is set; otherwise it checks every screen builds in every theme
// without layout errors.
//
// Run: SHOTS=<dir> flutter test test/misc/theme_shots_test.dart

import 'dart:async';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:drift/drift.dart' show driftRuntimeOptions;
import 'package:drift/native.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gridwell_flutter_app/content/puzzle_set.dart';
import 'package:gridwell_flutter_app/data/local/app_database.dart';
import 'package:gridwell_flutter_app/data/local/repositories.dart';
import 'package:gridwell_flutter_app/data/remote/api_client.dart';
import 'package:gridwell_flutter_app/services/purchases/store_service.dart';
import 'package:gridwell_flutter_app/state/monetization.dart';
import 'package:gridwell_flutter_app/state/online.dart';
import 'package:gridwell_flutter_app/state/providers.dart';
import 'package:gridwell_flutter_app/state/services.dart';
import 'package:gridwell_flutter_app/state/settings.dart';
import 'package:gridwell_flutter_app/state/themes.dart';
import 'package:gridwell_flutter_app/ui/router.dart';
import 'package:gridwell_flutter_app/ui/theme/gridwell_theme.dart';
import 'package:gridwell_flutter_app/ui/theme/palette.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import '../support/fonts.dart';

final _shotKey = GlobalKey();

/// (label, theme id, brightness for the standard theme, premium).
const _looks = [
  ('standard-light', 'standard', Brightness.light, false),
  ('standard-dark', 'standard', Brightness.dark, false),
  ('paper', 'paper', Brightness.light, false),
  ('midnight', 'midnight', Brightness.light, true),
  ('ink', 'ink', Brightness.light, true),
  ('ember', 'ember', Brightness.light, true),
  ('blossom', 'blossom', Brightness.light, true),
  ('violet', 'violet', Brightness.light, true),
  ('sky', 'sky', Brightness.light, true),
];

void main() {
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
  late PuzzleSet set;

  setUpAll(() async {
    await loadTallyFonts();
    set = PuzzleSetCodec.decode(File('assets/puzzles/set.bin').readAsBytesSync());
  });

  final routes = <String, String Function(PuzzleSet)>{
    'contents': (_) => '/contents',
    'board': (s) => '/play/${s.puzzles.firstWhere((p) => p.width == 10 && p.collectionId == 'coastline').id}',
    'daily': (_) => '/daily',
    'gallery': (_) => '/gallery',
    'collection': (s) => '/collection/${s.collections.first.id}',
    'settings': (_) => '/settings',
    'themes': (_) => '/themes',
    'store': (_) => '/store',
  };

  for (final (label, id, brightness, premium) in _looks) {
    for (final MapEntry(key: name, value: route) in routes.entries) {
      testWidgets('$name in $label', (tester) async {
        await _shoot(tester, set, '$name-$label', route(set), id, brightness, premium);
      });
    }
  }
  // A free player's preview of each Premium theme.
  for (final id in GridwellPalette.themes.keys) {
    testWidgets('preview of $id', (tester) async {
      await _shoot(tester, set, 'preview-$id', '/themes/preview/$id', 'standard', Brightness.light, false);
    });
  }
}

Future<void> _shoot(WidgetTester tester, PuzzleSet set, String name, String route, String themeId,
    Brightness brightness, bool premium) async {
  const size = Size(384, 832);
  tester.view.physicalSize = size * 2;
  tester.view.devicePixelRatio = 2;
  tester.view.padding = const FakeViewPadding(top: 60, bottom: 40);
  tester.view.viewPadding = const FakeViewPadding(top: 60, bottom: 40);
  addTearDown(tester.view.reset);

  final db = AppDatabase(NativeDatabase.memory());
  // A lived-in book: the first plates of every collection solved.
  await tester.runAsync(() async {
    final progress = ProgressRepository(db);
    final now = DateTime(2026, 11, 3, 12);
    for (final c in set.collections) {
      for (final p in set.puzzles.where((p) => p.collectionId == c.id).take(9)) {
        await progress.recordSolve(puzzleId: p.id, setVersion: set.puzzleSetVersion, timeMs: 83000, hintsUsed: 0, now: now);
      }
    }
  });

  // Prices as the stores would show them once the products exist.
  final store = StoreService()
    ..products.addAll({
      for (final key in paidThemeKeys) ProductIds.theme(key): r'$0.99',
      ProductIds.themeBundle: r'$2.99',
      ProductIds.removeAds: r'$1.99',
      ProductIds.premiumMonthly: r'$2.99',
      ProductIds.premiumYearly: r'$14.99',
    });
  final container = ProviderContainer(overrides: [
    storeServiceProvider.overrideWithValue(store),
    databaseProvider.overrideWithValue(db),
    puzzleSetProvider.overrideWithValue(set),
    initialSettingsProvider.overrideWithValue(Settings(
      onboardingDone: true,
      boardTourDone: true,
      themeId: themeId,
      themeMode: brightness == Brightness.dark ? ThemeMode.dark : ThemeMode.light,
    )),
    initialEntitlementsProvider.overrideWithValue(Entitlements(premium: premium)),
    apiClientProvider.overrideWithValue(ApiClient(
      baseUrl: 'http://localhost/api/v1',
      client: MockClient((_) async => http.Response('{"error":"offline"}', 503)),
    )),
  ]);

  final router = buildRouter(onboardingDone: true)..go(route);
  final palette = GridwellPalette.forTheme(themeId, brightness);
  await tester.pumpWidget(UncontrolledProviderScope(
    container: container,
    child: MaterialApp.router(
      debugShowCheckedModeBanner: false,
      builder: (context, child) => RepaintBoundary(key: _shotKey, child: child),
      routerConfig: router,
      theme: GridwellTheme.themeData(palette),
      localizationsDelegates: GlobalMaterialLocalizations.delegates,
    ),
  ));
  for (var i = 0; i < 6; i++) {
    await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 5)));
    await tester.pump(const Duration(milliseconds: 700));
  }

  final shots = Platform.environment['SHOTS'];
  if (shots != null) {
    final boundary = tester.renderObject<RenderRepaintBoundary>(find.byKey(_shotKey));
    await tester.runAsync(() async {
      final image = await boundary.toImage(pixelRatio: 2);
      final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
      File('$shots/$name.png').writeAsBytesSync(bytes!.buffer.asUint8List());
    });
  }

  await tester.pumpWidget(const SizedBox());
  router.dispose();
  container.dispose();
  await tester.pump(const Duration(seconds: 1));
  unawaited(db.close());
  await tester.pump(const Duration(seconds: 1));
}
