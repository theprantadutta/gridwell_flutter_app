import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../state/app_info.dart';
import '../../state/settings.dart';
import '../theme/gridwell_theme.dart';
import '../theme/palette.dart';
import '../theme/typography.dart';
import '../widgets/gridwell_mark.dart';

/// Picks up exactly where the native splash leaves off: the same ink ground in
/// either theme, the mark at the same 128 dp in the same place. The wordmark
/// and tagline then rise beneath it, and the ground fades to the book's paper.
///
/// About a second; static under reduced motion. Never waits on the network.
class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  static const markSize = 128.0;

  /// Matches `color` in flutter_native_splash.yaml.
  static const ground = Color(0xFF201914);

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1100),
  );
  double _leave = 1;

  @override
  void initState() {
    super.initState();
    // The Flutter splash is now drawn identically: hand over from the native one.
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
      await Future<void>.delayed(const Duration(milliseconds: 250));
    }
    if (!mounted) return;
    // Fade the ink away to the book's paper, then turn to it.
    setState(() => _leave = 0);
    await Future<void>.delayed(const Duration(milliseconds: 220));
    if (!mounted) return;
    context.go(
      ref.read(settingsProvider).onboardingDone ? '/contents' : '/onboarding',
    );
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  double _seg(double t, double from, double to) =>
      Curves.easeOutCubic.transform(((t - from) / (to - from)).clamp(0.0, 1.0));

  @override
  Widget build(BuildContext context) {
    final paper = context.palette.surface;
    // Cream type on ink in both themes, like the native splash.
    final p = GridwellPalette.of(Brightness.dark, highContrast: false);
    final version = ref.watch(appVersionProvider).value?.split(' ').first;
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          color: _leave == 1 ? SplashScreen.ground : paper,
          child: AnimatedOpacity(
            opacity: _leave,
            duration: const Duration(milliseconds: 200),
            child: LayoutBuilder(
              builder: (context, c) {
                // Centered in the full window, as the native splash is.
                final cx = c.maxWidth / 2, cy = c.maxHeight / 2;
                const m = SplashScreen.markSize;
                return AnimatedBuilder(
                  animation: _c,
                  builder: (context, _) {
                    final t = _c.value;
                    final word = _seg(t, 0.12, 0.50);
                    final tag = _seg(t, 0.30, 0.68);
                    final foot = _seg(t, 0.50, 0.85);
                    return Stack(
                      children: [
                        const Positioned.fill(child: SizedBox()),
                        Positioned(
                          left: cx - m / 2,
                          top: cy - m / 2,
                          child: CustomPaint(
                            size: const Size.square(m),
                            painter: GridwellMarkPainter(p, knockout: true),
                          ),
                        ),
                        Positioned(
                          left: 0,
                          right: 0,
                          top: cy + m / 2 + 30,
                          child: Column(
                            children: [
                              Opacity(
                                opacity: word,
                                child: Transform.translate(
                                  offset: Offset(0, 10 * (1 - word)),
                                  child: Text(
                                    'Gridwell',
                                    style: FolioType.style(
                                      size: 46,
                                      color: p.textPrimary,
                                      weight: 500,
                                      letterSpacing: -0.92,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 10),
                              Opacity(
                                opacity: tag,
                                child: Text(
                                  'NONOGRAM · PICROSS',
                                  style: FolioType.style(
                                    size: 12.5,
                                    color: p.accent,
                                    weight: 500,
                                    letterSpacing: 3,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        Positioned(
                          left: 0,
                          right: 0,
                          bottom: 40 + MediaQuery.paddingOf(context).bottom,
                          child: Opacity(
                            opacity: foot,
                            child: Column(
                              children: [
                                Text(
                                  'Setting the type…',
                                  style: FolioType.bodyMuted(p, size: 16),
                                ),
                                if (version != null) ...[
                                  const SizedBox(height: 6),
                                  Text(
                                    version,
                                    style: FolioType.style(
                                      size: 13,
                                      color: p.textFaint,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}
