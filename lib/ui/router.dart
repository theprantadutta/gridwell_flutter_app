import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'screens/board_screen.dart';
import 'screens/collection_screen.dart';
import 'screens/completion_screen.dart';
import 'screens/contents_screen.dart';
import 'screens/home_shell.dart';

GoRouter buildRouter({required bool onboardingDone}) => GoRouter(
      initialLocation: onboardingDone ? '/contents' : '/onboarding',
      routes: [
        GoRoute(path: '/onboarding', builder: (_, _) => const OnboardingPlaceholder()),
        ShellRoute(
          builder: (context, state, child) => HomeShell(location: state.uri.path, child: child),
          routes: [
            GoRoute(path: '/contents', pageBuilder: (_, _) => const NoTransitionPage(child: ContentsScreen())),
            GoRoute(path: '/daily', pageBuilder: (_, _) => const NoTransitionPage(child: TabPlaceholder('The Daily'))),
            GoRoute(path: '/gallery', pageBuilder: (_, _) => const NoTransitionPage(child: TabPlaceholder('Gallery'))),
            GoRoute(path: '/settings', pageBuilder: (_, _) => const NoTransitionPage(child: TabPlaceholder('Settings'))),
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
      ],
    );
