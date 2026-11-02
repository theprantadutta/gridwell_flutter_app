import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'firebase_options.dart';
import 'services/feedback/sound_haptic_feedback.dart';
import 'state/providers.dart';
import 'state/services.dart';
import 'state/settings.dart';
import 'ui/app.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  LicenseRegistry.addLicense(() async* {
    yield LicenseEntryWithLineBreaks(['Literata'], await rootBundle.loadString('assets/fonts/OFL.txt'));
  });

  // Firebase is enrichment only: the game must start without it.
  try {
    await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  } catch (e) {
    debugPrint('Firebase unavailable: $e');
  }

  final overrides = await bootstrapOverrides();
  final feedback = await SoundHapticFeedback.create();
  runApp(ProviderScope(
    overrides: [...overrides, feedbackProvider.overrideWithValue(feedback)],
    child: const _FeedbackSettingsSync(child: GridwellApp()),
  ));
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
    return child;
  }
}
