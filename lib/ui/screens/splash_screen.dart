import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../state/settings.dart';
import '../theme/gridwell_theme.dart';
import '../theme/typography.dart';
import '../widgets/gridwell_mark.dart';

/// Picks up exactly where the native splash leaves off: the theme's `--bg`
/// with the mark at [markSize], centered in the full window. The wordmark
/// rises beneath it while a row of ticks fills, then the app turns to Home
/// (or onboarding the first time).
///
/// About a second; static under reduced motion. Never waits on the network.
class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  /// Matches the native splash image (brand/make_splash.py).
  static const markSize = 104.0;

  /// The wordmark's font size and its gap below the mark.
  static const wordmarkSize = 46.0, wordmarkGap = 26.0;

  static const ticks = 20;

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 1000));

  @override
  void initState() {
    super.initState();
    // The Flutter splash is drawn identically: hand over from the native one.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      FlutterNativeSplash.remove();
      _run();
    });
  }

  Future<void> _run() async {
    final reduced = MediaQuery.maybeDisableAnimationsOf(context) ?? false;
    if (reduced) {
      _c.value = 1;
      await Future<void>.delayed(const Duration(milliseconds: 300));
    } else {
      await _c.forward().orCancel.catchError((_) {});
      await Future<void>.delayed(const Duration(milliseconds: 150));
    }
    if (!mounted) return;
    context.go(ref.read(settingsProvider).onboardingDone ? '/contents' : '/onboarding');
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: p.isDark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark,
      child: Scaffold(
        backgroundColor: p.bg,
        body: LayoutBuilder(
          builder: (context, c) {
            // Centered in the full window, as the native splash is.
            final cx = c.maxWidth / 2, cy = c.maxHeight / 2;
            const m = SplashScreen.markSize;
            return AnimatedBuilder(
              animation: _c,
              builder: (context, _) {
                final t = _c.value;
                final word = Curves.easeOutCubic.transform((t / 0.45).clamp(0.0, 1.0));
                final foot = Curves.easeOut.transform(((t - 0.1) / 0.3).clamp(0.0, 1.0));
                final lit = (Curves.easeInOut.transform(t) * SplashScreen.ticks).round();
                return Stack(children: [
                  Positioned(
                    left: cx - m / 2,
                    top: cy - m / 2,
                    child: const GridwellMark(size: m),
                  ),
                  Positioned(
                    left: 0,
                    right: 0,
                    top: cy + m / 2 + SplashScreen.wordmarkGap,
                    child: Opacity(
                      opacity: word,
                      child: Transform.translate(
                        offset: Offset(0, 8 * (1 - word)),
                        child: const Center(child: GridwellWordmark(size: SplashScreen.wordmarkSize)),
                      ),
                    ),
                  ),
                  Positioned(
                    left: 0,
                    right: 0,
                    bottom: 40 + MediaQuery.paddingOf(context).bottom,
                    child: Opacity(
                      opacity: foot,
                      child: Column(children: [
                        Semantics(
                          label: 'Loading',
                          child: Row(mainAxisSize: MainAxisSize.min, children: [
                            for (var i = 0; i < SplashScreen.ticks; i++) ...[
                              if (i > 0) const SizedBox(width: 2),
                              Container(width: 8, height: 6, color: i < lit ? p.lime : p.track),
                            ],
                          ]),
                        ),
                        const SizedBox(height: 18),
                        Text('NONOGRAM · PICROSS', style: TallyType.overline(p.ink2).copyWith(fontSize: 11.5)),
                      ]),
                    ),
                  ),
                ]);
              },
            );
          },
        ),
      ),
    );
  }
}
