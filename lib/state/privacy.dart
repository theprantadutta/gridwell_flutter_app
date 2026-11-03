import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'services.dart';
import 'settings.dart';

/// True where players must be able to revisit ad consent (EEA/UK).
final adChoicesAvailableProvider = FutureProvider<bool>(
  (ref) => ref.watch(adServiceProvider).privacyOptionsRequired(),
);

class PrivacyActions {
  PrivacyActions(this._ref);

  final Ref _ref;

  Future<void> showAdChoices() => _ref.read(adServiceProvider).showPrivacyOptions();

  Future<void> setShareAnalytics(bool on) async {
    await _ref.read(settingsProvider.notifier).update((s) => s.copyWith(shareAnalytics: on));
    await _ref.read(analyticsProvider).setEnabled(on);
  }
}

final privacyActionsProvider = Provider((ref) => PrivacyActions(ref));
