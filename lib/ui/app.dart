import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show SystemUiOverlayStyle;
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart' as material_ui;

import '../state/dev_seeder.dart';
import '../state/display.dart';
import '../state/monetization.dart';
import '../state/online.dart';
import '../state/reminders.dart';
import '../state/settings.dart';
import '../state/store_prompts.dart';
import '../state/telemetry.dart';
import 'router.dart';
import 'theme/gridwell_theme.dart';
import 'theme/palette.dart';

class GridwellApp extends ConsumerStatefulWidget {
  const GridwellApp({super.key});

  @override
  ConsumerState<GridwellApp> createState() => _GridwellAppState();
}

class _GridwellAppState extends ConsumerState<GridwellApp> {
  late final GoRouter _router =
      buildRouter(onboardingDone: ref.read(settingsProvider).onboardingDone);
  late final AppLifecycleListener _lifecycle;

  @override
  void initState() {
    super.initState();
    // On start and every resume: online enrichment, purchase reconcile and the
    // reminder schedule. Never awaited, never blocking play.
    _onForeground();
    ref.read(pushRegistrarProvider).listen();
    ref.read(devDataSeederProvider).runIfRequested(); // debug builds only
    ref.read(purchaseControllerProvider);
    // Analytics screen views and crash-report context follow navigation.
    // Listened, not just read: Riverpod pauses providers nobody listens to,
    // which would stop the account and entitlement updates.
    final telemetry = ref.listenManual(telemetryProvider, (_, _) {}).read();
    _router.routerDelegate.addListener(() {
      final config = _router.routerDelegate.currentConfiguration;
      if (config.isEmpty) return;
      telemetry.route(config.fullPath, puzzleId: config.pathParameters['id']);
    });
    _lifecycle = AppLifecycleListener(onResume: _onForeground);
    // Smooth motion: after the first frame (the plugin needs the rendering
    // surface attached), then again on every resume and setting change.
    // Listened, not just read, so Riverpod keeps it awake.
    ref.listenManual(displayRateProvider, (_, _) {});
    WidgetsBinding.instance.addPostFrameCallback((_) => ref.read(displayRateProvider.notifier).apply());
    // After the splash, so an update offer never lands on top of it.
    Future<void>.delayed(const Duration(seconds: 3), () {
      if (mounted) ref.read(updateReadyProvider.notifier).check();
    });
  }

  void _onForeground() {
    // Android can drop the window's preferred display mode in the background.
    ref.read(displayRateProvider.notifier).apply();
    ref.read(onlineSessionProvider).onForeground().then((_) => ref.read(pushRegistrarProvider).register());
    ref.read(reminderSchedulerProvider).reschedule();
  }

  @override
  void dispose() {
    _lifecycle.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(settingsProvider);
    return MaterialApp.router(
      title: 'Gridwell',
      debugShowCheckedModeBanner: false,
      routerConfig: _router,
      // Status and navigation bar icons follow the theme (light icons on the
      // dark Tally green, dark icons on paper). Screens may override.
      builder: (context, child) => AnnotatedRegion<SystemUiOverlayStyle>(
        // Edge to edge (main.dart): transparent bars, so the tab bar and
        // bottom slabs run under the navigation bar as in the kit.
        value: tallyOverlay(Theme.of(context).brightness == Brightness.dark),
        child: child ?? const SizedBox(),
      ),
      themeMode: settings.themeMode,
      theme: GridwellTheme.themeData(
          GridwellPalette.of(Brightness.light, highContrast: settings.highContrast)),
      darkTheme: GridwellTheme.themeData(
          GridwellPalette.of(Brightness.dark, highContrast: settings.highContrast)),
      // go_router and other migrated packages use package:material_ui, whose
      // MaterialLocalizations is a different type from Flutter's. Register both.
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        ...material_ui.GlobalMaterialLocalizations.delegates,
      ],
      supportedLocales: const [Locale('en', 'US')],
    );
  }
}
