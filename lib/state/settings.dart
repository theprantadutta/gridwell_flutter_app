import 'package:flutter/material.dart' show ThemeMode;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'providers.dart';

/// Player settings. Stored locally first; synced last-write-wins.
class Settings {
  const Settings({
    this.themeMode = ThemeMode.system,
    this.sound = true,
    this.haptics = true,
    this.showProvenMistakes = true,
    this.autoCross = true,
    this.showTimer = true,
    this.highContrast = false,
    this.onboardingDone = false,
    this.notificationsAsked = false,
    this.dailyReminder = true,
    this.shareAnalytics = true,
  });

  final ThemeMode themeMode;
  final bool sound;
  final bool haptics;
  final bool showProvenMistakes;
  final bool autoCross;
  final bool showTimer;
  final bool highContrast;
  final bool onboardingDone;
  final bool notificationsAsked;
  final bool dailyReminder;

  /// Anonymous usage statistics (Firebase Analytics). Off stops collection.
  final bool shareAnalytics;

  Settings copyWith({
    ThemeMode? themeMode,
    bool? sound,
    bool? haptics,
    bool? showProvenMistakes,
    bool? autoCross,
    bool? showTimer,
    bool? highContrast,
    bool? onboardingDone,
    bool? notificationsAsked,
    bool? dailyReminder,
    bool? shareAnalytics,
  }) =>
      Settings(
        themeMode: themeMode ?? this.themeMode,
        sound: sound ?? this.sound,
        haptics: haptics ?? this.haptics,
        showProvenMistakes: showProvenMistakes ?? this.showProvenMistakes,
        autoCross: autoCross ?? this.autoCross,
        showTimer: showTimer ?? this.showTimer,
        highContrast: highContrast ?? this.highContrast,
        onboardingDone: onboardingDone ?? this.onboardingDone,
        notificationsAsked: notificationsAsked ?? this.notificationsAsked,
        dailyReminder: dailyReminder ?? this.dailyReminder,
        shareAnalytics: shareAnalytics ?? this.shareAnalytics,
      );

  Map<String, String> toMap() => {
        'theme_mode': themeMode.name,
        'sound': '$sound',
        'haptics': '$haptics',
        'show_proven_mistakes': '$showProvenMistakes',
        'auto_cross': '$autoCross',
        'show_timer': '$showTimer',
        'high_contrast': '$highContrast',
        'onboarding_done': '$onboardingDone',
        'notifications_asked': '$notificationsAsked',
        'daily_reminder': '$dailyReminder',
        'share_analytics': '$shareAnalytics',
      };

  factory Settings.fromMap(Map<String, String> m) {
    bool b(String k, bool d) => m[k] == null ? d : m[k] == 'true';
    return Settings(
      themeMode: ThemeMode.values.firstWhere(
        (t) => t.name == m['theme_mode'],
        orElse: () => ThemeMode.system,
      ),
      sound: b('sound', true),
      haptics: b('haptics', true),
      showProvenMistakes: b('show_proven_mistakes', true),
      autoCross: b('auto_cross', true),
      showTimer: b('show_timer', true),
      highContrast: b('high_contrast', false),
      onboardingDone: b('onboarding_done', false),
      notificationsAsked: b('notifications_asked', false),
      dailyReminder: b('daily_reminder', true),
      shareAnalytics: b('share_analytics', true),
    );
  }
}

/// Settings, loaded at startup (see [initialSettingsProvider]) and written
/// through to the database on every change.
class SettingsNotifier extends Notifier<Settings> {
  @override
  Settings build() => ref.watch(initialSettingsProvider);

  Future<void> update(Settings Function(Settings) change) async {
    final before = state;
    final next = change(before);
    if (identical(next, before)) return;
    state = next;
    final repo = ref.read(settingsRepositoryProvider);
    final now = DateTime.now();
    final a = before.toMap(), b = next.toMap();
    for (final key in b.keys) {
      if (a[key] != b[key]) await repo.put(key, b[key]!, now);
    }
  }
}

final settingsProvider = NotifierProvider<SettingsNotifier, Settings>(SettingsNotifier.new);
