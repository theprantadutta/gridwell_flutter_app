import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart' as material_ui;

import '../state/online.dart';
import '../state/settings.dart';
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
    // Online enrichment on start and every resume: never awaited, never blocking.
    ref.read(onlineSessionProvider).onForeground();
    _lifecycle = AppLifecycleListener(onResume: () => ref.read(onlineSessionProvider).onForeground());
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
