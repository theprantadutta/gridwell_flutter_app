// Renders the settings, store, account, privacy, legal, onboarding and splash
// screens on the kit's 390 x 844 frame in both themes, for a visual comparison
// with the Tally kit. Writes PNGs only when SHOTS=<dir> is set; otherwise it
// just checks the screens build without layout errors.
//
// Run: SHOTS=<dir> flutter test test/misc/tally_screens_shots_test.dart

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
import 'package:gridwell_flutter_app/data/remote/api_client.dart';
import 'package:gridwell_flutter_app/state/online.dart';
import 'package:gridwell_flutter_app/state/providers.dart';
import 'package:gridwell_flutter_app/state/settings.dart';
import 'package:gridwell_flutter_app/ui/screens/account_screen.dart';
import 'package:gridwell_flutter_app/ui/screens/email_auth_screen.dart';
import 'package:gridwell_flutter_app/ui/screens/legal_screen.dart';
import 'package:gridwell_flutter_app/ui/screens/onboarding_screen.dart';
import 'package:gridwell_flutter_app/ui/screens/privacy_screen.dart';
import 'package:gridwell_flutter_app/ui/screens/settings_screen.dart';
import 'package:gridwell_flutter_app/ui/screens/splash_screen.dart';
import 'package:gridwell_flutter_app/ui/screens/store_screen.dart';
import 'package:gridwell_flutter_app/ui/theme/gridwell_theme.dart';
import 'package:gridwell_flutter_app/ui/theme/palette.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:material_ui/material_ui.dart' as material_ui;

import '../support/fonts.dart';

final _shotKey = GlobalKey();

void main() {
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
  late PuzzleSet set;

  setUpAll(() async {
    await loadTallyFonts();
    set = PuzzleSetCodec.decode(File('assets/puzzles/set.bin').readAsBytesSync());
  });

  final screens = <String, Widget Function()>{
    'settings': () => const Scaffold(body: SafeArea(child: SettingsScreen())),
    'store': () => const StoreScreen(),
    'account': () => const AccountScreen(),
    'account-email': () => const EmailAuthScreen(),
    'privacy': () => const PrivacyScreen(),
    'legal': () => const LegalScreen(doc: LegalDoc.terms),
    'onboarding': () => const OnboardingScreen(),
    'splash': () => const SplashScreen(),
  };

  for (final MapEntry(key: name, value: build) in screens.entries) {
    for (final (sizeName, size) in [('kit', const Size(390, 844)), ('phone-320', const Size(320, 640))]) {
      for (final scale in [1.0, 1.3]) {
        for (final dark in [false, true]) {
          testWidgets('$name @ $sizeName x$scale ${dark ? 'dark' : 'light'}', (tester) async {
            await _shoot(tester, set, name, build, size, scale, dark, sizeName);
          });
        }
      }
    }
  }
}

Future<void> _shoot(WidgetTester tester, PuzzleSet set, String name, Widget Function() build, Size size, double scale,
    bool dark, String sizeName) async {
  tester.view.physicalSize = size * 2;
  tester.view.devicePixelRatio = 2;
  tester.view.padding = const FakeViewPadding(top: 100, bottom: 68);
  tester.view.viewPadding = const FakeViewPadding(top: 100, bottom: 68);
  tester.platformDispatcher.textScaleFactorTestValue = scale;
  addTearDown(tester.view.reset);
  addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);

  final db = AppDatabase(NativeDatabase.memory());
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

  final router = GoRouter(initialLocation: '/s', routes: [
    GoRoute(path: '/s', builder: (_, _) => build()),
    GoRoute(path: '/contents', builder: (_, _) => const SizedBox()),
    GoRoute(path: '/onboarding', builder: (_, _) => const SizedBox()),
  ]);
  final palette = GridwellPalette.of(dark ? Brightness.dark : Brightness.light);
  await tester.pumpWidget(UncontrolledProviderScope(
    container: container,
    child: MaterialApp.router(
      debugShowCheckedModeBanner: false,
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

  final shots = Platform.environment['SHOTS'];
  Future<void> shot(String suffix) async {
    if (shots == null || sizeName != 'kit' || scale != 1.0) return;
    final boundary = tester.renderObject<RenderRepaintBoundary>(find.byKey(_shotKey));
    await tester.runAsync(() async {
      final image = await boundary.toImage(pixelRatio: 2);
      final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
      File('$shots/$name$suffix-${dark ? 'dark' : 'light'}.png').writeAsBytesSync(bytes!.buffer.asUint8List());
    });
  }

  if (name == 'splash') {
    // Before the turn to Home: the ticks are full at 1 s.
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 1000));
    await shot('');
    await tester.pump(const Duration(milliseconds: 600));
  } else {
    for (var i = 0; i < 4; i++) {
      await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 5)));
      await tester.pump(const Duration(milliseconds: 400));
    }
    await shot('');
    if (name == 'onboarding') {
      for (final page in ['-2', '-3']) {
        await tester.tap(find.text('NEXT'));
        await tester.pumpAndSettle();
        await shot(page);
      }
    }
  }

  await tester.pumpWidget(const SizedBox());
  router.dispose();
  container.dispose();
  await tester.pump(const Duration(seconds: 1));
  unawaited(db.close());
  await tester.pump(const Duration(seconds: 1));
}
