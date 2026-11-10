import 'dart:async';
import 'dart:isolate';

import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'firebase_options.dart';
import 'services/analytics/analytics_service.dart';
import 'services/config/app_env.dart';
import 'services/crash/crash_reporter.dart';
import 'services/crash/firebase_crash_reporter.dart';
import 'services/analytics/firebase_analytics_service.dart';
import 'services/ads/google_ad_service.dart';
import 'services/feedback/sound_haptic_feedback.dart';
import 'services/notifications/notification_service.dart';
import 'services/purchases/store_service.dart';
import 'state/monetization.dart';
import 'state/reminders.dart';
import 'state/providers.dart';
import 'state/services.dart';
import 'state/settings.dart';
import 'ui/app.dart';

Future<void> main() async {
  final binding = WidgetsFlutterBinding.ensureInitialized();
  // Keep the native splash up through start-up; the Flutter splash takes over
  // on its first frame (lib/ui/screens/splash_screen.dart).
  FlutterNativeSplash.preserve(widgetsBinding: binding);

  // Phones are portrait-only; tablets (shortest side >= 600 dp) may rotate.
  final view = PlatformDispatcher.instance.views.first;
  final shortest = view.physicalSize.shortestSide / view.devicePixelRatio;
  if (shortest < 600) {
    await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  }

  await SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);

  await AppEnv.load();

  LicenseRegistry.addLicense(() async* {
    yield LicenseEntryWithLineBreaks([
      'Schibsted Grotesk',
    ], await rootBundle.loadString('assets/fonts/OFL.txt'));
  });

  // Firebase is enrichment only: the game must start without it. Analytics
  // and crash reporting run in release builds only, never in debug or profile.
  AnalyticsService analytics = MemoryAnalytics();
  CrashReporter crash = const NoopCrashReporter();
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    await FirebaseCrashlytics.instance.setCrashlyticsCollectionEnabled(
      kReleaseMode,
    );
    if (!kReleaseMode) {
      await FirebaseAnalytics.instance.setAnalyticsCollectionEnabled(false);
    } else {
      analytics = FirebaseAnalyticsService(FirebaseAnalytics.instance);
      // Crash reporting: Flutter framework errors and uncaught async errors.
      FlutterError.onError =
          FirebaseCrashlytics.instance.recordFlutterFatalError;
      PlatformDispatcher.instance.onError = (error, stack) {
        FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
        return true;
      };
      // Errors thrown in background isolates (decoding, the solver).
      Isolate.current.addErrorListener(RawReceivePort((List<dynamic> pair) {
        FirebaseCrashlytics.instance.recordError(
          pair.first,
          pair.last == null ? null : StackTrace.fromString(pair.last.toString()),
          fatal: true,
        );
      }).sendPort);
      // Caught errors and report context (user, screen, puzzle).
      crash = FirebaseCrashReporter(FirebaseCrashlytics.instance);
      CrashReports.instance = crash;
    }
  } catch (e) {
    debugPrint('Firebase unavailable: $e');
  }

  final overrides = await bootstrapOverrides();
  final feedback = await SoundHapticFeedback.create();
  final notifications = NotificationService();
  await notifications.initialize();
  // Store and ads connect in the background: they must never delay launch.
  final store = StoreService();
  unawaited(store.initialize());
  final ads = GoogleAdService(
    onUnavailableGrant: (placement) =>
        analytics.log('ad_unavailable_grant', {'placement': placement.name}),
  );
  unawaited(ads.initialize());
  runApp(
    ProviderScope(
      overrides: [
        ...overrides,
        feedbackProvider.overrideWithValue(feedback),
        analyticsProvider.overrideWithValue(analytics),
        crashReporterProvider.overrideWithValue(crash),
        adServiceProvider.overrideWithValue(ads),
        storeServiceProvider.overrideWithValue(store),
        notificationServiceProvider.overrideWithValue(notifications),
      ],
      child: const _FeedbackSettingsSync(child: GridwellApp()),
    ),
  );
}

/// Keeps the feedback service in step with the Sound and Haptics settings.
class _FeedbackSettingsSync extends ConsumerWidget {
  const _FeedbackSettingsSync({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(settingsProvider);
    ref.read(feedbackProvider)
      ..soundEnabled = s.sound
      ..hapticsEnabled = s.haptics;
    ref.read(analyticsProvider).setEnabled(s.shareAnalytics);
    return child;
  }
}
