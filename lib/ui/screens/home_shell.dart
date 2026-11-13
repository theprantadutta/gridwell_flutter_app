import 'package:flutter/services.dart' show SystemNavigator;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:go_router/go_router.dart';

import '../../state/settings.dart';
import 'settings_screen.dart' show TallyDialogText, showTallyDialog;

import '../theme/gridwell_theme.dart';
import '../theme/typography.dart';
import '../widgets/tally.dart';

/// The four tabs: Play, Daily, Gallery, Settings. Text tabs on a `--surface`
/// bar under a 1 pt `--sunk` rule, with a 22 × 3 pt lime bar over the current
/// one. 84 pt tall including the home-indicator inset.
class HomeShell extends ConsumerWidget {
  const HomeShell({super.key, required this.location, required this.child});

  final String location;
  final Widget child;

  static const _tabs = [
    ('/contents', 'Play'),
    ('/daily', 'Daily'),
    ('/gallery', 'Gallery'),
    ('/settings', 'Settings'),
  ];

  /// Content width on tablets.
  static const maxWidth = 760.0;

  /// Back on Daily, Gallery or Settings returns to Play. Back on Play closes
  /// the app, after asking first unless the player turned that off.
  Future<void> _onBack(BuildContext context, WidgetRef ref) async {
    if (!location.startsWith('/contents')) {
      context.go('/contents');
      return;
    }
    if (!ref.read(settingsProvider).confirmExit) {
      await SystemNavigator.pop();
      return;
    }
    final leave = await showTallyDialog<bool>(
      context: context,
      title: 'Leave Gridwell?',
      body: const TallyDialogText(
        'Your progress is saved. Any puzzle you started will be waiting when you come back.',
      ),
      cancel: 'Stay',
      confirm: 'Leave',
      onConfirm: () => true,
    );
    if (leave == true) await SystemNavigator.pop();
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final p = context.palette;
    final inset = MediaQuery.paddingOf(context).bottom;
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _onBack(context, ref);
      },
      child: Scaffold(
        body: SafeArea(
          bottom: false,
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: maxWidth),
              child: child,
            ),
          ),
        ),
        bottomNavigationBar: DecoratedBox(
          decoration: BoxDecoration(
            color: p.surface,
            border: Border(
              top: BorderSide(color: p.sunk, width: tallyDivider),
            ),
          ),
          child: Padding(
            padding: EdgeInsets.only(bottom: inset),
            child: Center(
              heightFactor: 1,
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: maxWidth),
                // Grows with the text size instead of clipping.
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    minHeight: (84 - inset).clamp(62, 84).toDouble(),
                  ),
                  child: Row(
                    children: [
                      for (final (path, label) in _tabs)
                        Expanded(
                          child: _Tab(
                            label: label,
                            selected: location.startsWith(path),
                            onTap: () => context.go(path),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _Tab extends StatelessWidget {
  const _Tab({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Semantics(
      button: true,
      selected: selected,
      label: label,
      excludeSemantics: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.only(top: 18, bottom: 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 22,
                height: 3,
                color: selected ? p.lime : Colors.transparent,
              ),
              const SizedBox(height: 9),
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  label,
                  maxLines: 1,
                  style: TallyType.body(selected ? p.ink : p.ink2).copyWith(
                    fontSize: 14,
                    fontWeight: selected ? FontWeight.w800 : FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
