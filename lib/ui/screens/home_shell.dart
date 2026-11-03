import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../theme/gridwell_theme.dart';
import '../theme/typography.dart';
import '../widgets/folio.dart';

/// The four tabs: Contents, Daily, Gallery, Settings. Text tabs over a
/// hairline, with a short accent bar over the current one.
class HomeShell extends StatelessWidget {
  const HomeShell({super.key, required this.location, required this.child});

  final String location;
  final Widget child;

  static const _tabs = [
    ('/contents', 'Contents'),
    ('/daily', 'Daily'),
    ('/gallery', 'Gallery'),
    ('/settings', 'Settings'),
  ];

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Scaffold(
      // Book pages keep a reading width on tablets.
      body: SafeArea(
        bottom: false,
        child: Center(
          child: ConstrainedBox(constraints: const BoxConstraints(maxWidth: 760), child: child),
        ),
      ),
      bottomNavigationBar: SafeArea(
        top: false,
        // Same centered width as the page above it.
        child: Center(
          heightFactor: 1,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 760),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: folioMargin),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Hairline(),
                  // Grows with the text size instead of clipping; never shorter than 64.
                  ConstrainedBox(
                    constraints: const BoxConstraints(minHeight: 64),
                    child: Row(
                      children: [
                        for (final (path, label) in _tabs)
                          Expanded(
                            child: Semantics(
                              button: true,
                              selected: location.startsWith(path),
                              label: label,
                              child: GestureDetector(
                                behavior: HitTestBehavior.opaque,
                                onTap: () => context.go(path),
                                child: Padding(
                                  padding: const EdgeInsets.only(bottom: 10),
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Container(
                                        width: 40,
                                        height: 3,
                                        color: location.startsWith(path) ? p.accent : Colors.transparent,
                                      ),
                                      const SizedBox(height: 12),
                                      FittedBox(
                                        fit: BoxFit.scaleDown,
                                        child: Text(
                                          label,
                                          maxLines: 1,
                                          style: FolioType.tab(
                                            location.startsWith(path) ? p.textPrimary : p.textMuted,
                                            selected: location.startsWith(path),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Stand-in for tabs still being built.
class TabPlaceholder extends StatelessWidget {
  const TabPlaceholder(this.title, {super.key});

  final String title;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const WordmarkHeader(),
        Padding(
          padding: const EdgeInsets.fromLTRB(folioMargin, 28, folioMargin, 0),
          child: Text(title, style: FolioType.display(p)),
        ),
      ],
    );
  }
}
