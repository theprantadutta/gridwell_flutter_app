import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'screens/about_screen.dart';
import 'screens/account_screen.dart';
import 'screens/board_screen.dart';
import 'screens/collection_screen.dart';
import 'screens/completion_screen.dart';
import 'screens/contents_screen.dart';
import 'screens/daily_screen.dart';
import 'screens/email_auth_screen.dart';
import 'screens/gallery_screen.dart';
import 'screens/home_shell.dart';
import 'screens/legal_screen.dart';
import 'screens/onboarding_screen.dart';
import 'screens/plate_screen.dart';
import 'screens/privacy_screen.dart';
import 'screens/settings_screen.dart';
import 'screens/splash_screen.dart';
import 'screens/store_screen.dart';

GoRouter buildRouter({required bool onboardingDone}) => GoRouter(
      // The splash decides where to go next (contents, or onboarding first time).
      initialLocation: '/splash',
      routes: [
        GoRoute(path: '/splash', pageBuilder: (_, _) => const NoTransitionPage(child: SplashScreen())),
        GoRoute(path: '/onboarding', builder: (_, _) => const OnboardingScreen()),
        ShellRoute(
          builder: (context, state, child) => HomeShell(location: state.uri.path, child: child),
          routes: [
            GoRoute(path: '/contents', pageBuilder: (_, _) => const NoTransitionPage(child: ContentsScreen())),
            GoRoute(path: '/daily', pageBuilder: (_, _) => const NoTransitionPage(child: DailyScreen())),
            GoRoute(path: '/gallery', pageBuilder: (_, _) => const NoTransitionPage(child: GalleryScreen())),
            GoRoute(path: '/settings', pageBuilder: (_, _) => const NoTransitionPage(child: SettingsScreen())),
          ],
        ),
        GoRoute(
          path: '/collection/:id',
          builder: (_, state) => CollectionScreen(collectionId: state.pathParameters['id']!),
        ),
        GoRoute(
          path: '/play/:id',
          builder: (_, state) => BoardScreen(key: ValueKey(state.pathParameters['id']), puzzleId: state.pathParameters['id']!),
        ),
        GoRoute(path: '/complete', builder: (_, _) => const CompletionScreen()),
        GoRoute(path: '/plate/:id', builder: (_, state) => PlateScreen(puzzleId: state.pathParameters['id']!)),
        GoRoute(
          path: '/store',
          builder: (_, state) => StoreScreen(restoreOnOpen: state.uri.queryParameters['restore'] == '1'),
        ),
        GoRoute(path: '/privacy', builder: (_, _) => const PrivacyScreen()),
        GoRoute(path: '/about', builder: (_, _) => const AboutScreen()),
        GoRoute(path: '/account', builder: (_, _) => const AccountScreen()),
        GoRoute(path: '/account/email', builder: (_, _) => const EmailAuthScreen()),
        GoRoute(
          path: '/legal/:doc',
          builder: (_, state) => LegalScreen(
            doc: LegalDoc.values.firstWhere((d) => d.name == state.pathParameters['doc'], orElse: () => LegalDoc.privacy),
          ),
        ),
      ],
    );
