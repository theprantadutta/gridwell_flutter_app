import 'dart:async';

import 'package:flutter/material.dart' show ThemeMode;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/analytics/analytics_service.dart';
import 'online.dart';
import 'providers.dart';
import 'services.dart';

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
    this.boardTourDone = false,
    this.reviewAskedMs = 0,
    this.updateDeclinedMs = 0,
    this.notificationsAsked = false,
    this.dailyReminder = true,
    this.shareAnalytics = true,
    this.highRefreshRate = true,
  });

  final ThemeMode themeMode;
  final bool sound;
  final bool haptics;
  final bool showProvenMistakes;
  final bool autoCross;
  final bool showTimer;
  final bool highContrast;
  final bool onboardingDone;

  /// The first-game walkthrough has been finished or skipped on this device.
  final bool boardTourDone;

  /// When the review sheet was last requested. 0 is never.
  final int reviewAskedMs;

  /// When a Play update offer was last declined. 0 is never.
  final int updateDeclinedMs;
  final bool notificationsAsked;
  final bool dailyReminder;

  /// Anonymous usage statistics (Firebase Analytics). Off stops collection.
  final bool shareAnalytics;

  /// Ask the display for its highest refresh rate ("Smooth motion"). On by
  /// default: a 120 Hz screen otherwise runs the app at 60 Hz. Kept per
  /// device, not synced: whether it is worth the battery depends on the
  /// hardware in hand.
  final bool highRefreshRate;

  Settings copyWith({
    ThemeMode? themeMode,
    bool? sound,
    bool? haptics,
    bool? showProvenMistakes,
    bool? autoCross,
    bool? showTimer,
    bool? highContrast,
    bool? onboardingDone,
    bool? boardTourDone,
    int? reviewAskedMs,
    int? updateDeclinedMs,
    bool? notificationsAsked,
    bool? dailyReminder,
    bool? shareAnalytics,
    bool? highRefreshRate,
  }) => Settings(
    themeMode: themeMode ?? this.themeMode,
    sound: sound ?? this.sound,
    haptics: haptics ?? this.haptics,
    showProvenMistakes: showProvenMistakes ?? this.showProvenMistakes,
    autoCross: autoCross ?? this.autoCross,
    showTimer: showTimer ?? this.showTimer,
    highContrast: highContrast ?? this.highContrast,
    onboardingDone: onboardingDone ?? this.onboardingDone,
    boardTourDone: boardTourDone ?? this.boardTourDone,
        reviewAskedMs: reviewAskedMs ?? this.reviewAskedMs,
        updateDeclinedMs: updateDeclinedMs ?? this.updateDeclinedMs,
    notificationsAsked: notificationsAsked ?? this.notificationsAsked,
    dailyReminder: dailyReminder ?? this.dailyReminder,
    shareAnalytics: shareAnalytics ?? this.shareAnalytics,
    highRefreshRate: highRefreshRate ?? this.highRefreshRate,
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
    'board_tour_done': '$boardTourDone',
        'review_asked_ms': '$reviewAskedMs',
        'update_declined_ms': '$updateDeclinedMs',
    'notifications_asked': '$notificationsAsked',
    'daily_reminder': '$dailyReminder',
    'share_analytics': '$shareAnalytics',
    'high_refresh_rate': '$highRefreshRate',
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
      boardTourDone: b('board_tour_done', false),
      reviewAskedMs: int.tryParse(m['review_asked_ms'] ?? '') ?? 0,
      updateDeclinedMs: int.tryParse(m['update_declined_ms'] ?? '') ?? 0,
      notificationsAsked: b('notifications_asked', false),
      dailyReminder: b('daily_reminder', true),
      shareAnalytics: b('share_analytics', true),
      highRefreshRate: b('high_refresh_rate', true),
    );
  }
}

/// Settings, loaded at startup (see [initialSettingsProvider]) and written
/// through to the database on every change.
/// Settings the player changes in Settings (logged as `settings_changed`).
/// Internal flags such as `review_asked_ms` or `board_tour_done` are left out.
const playerSettingKeys = [
  'theme_mode',
  'sound',
  'haptics',
  'show_proven_mistakes',
  'auto_cross',
  'show_timer',
  'high_contrast',
  'daily_reminder',
  'share_analytics',
  'high_refresh_rate',
];

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
    // Choices the player makes in Settings, not the app's own bookkeeping.
    for (final key in playerSettingKeys) {
      if (a[key] != b[key]) {
        unawaited(ref.read(analyticsProvider).log(AnalyticsEvents.settingsChanged, {'setting': key, 'value': b[key]!}));
      }
    }
    if (syncedSettingKeys.any((k) => a[k] != b[k])) {
      unawaited(
        ref.read(onlineSessionProvider).enqueue('settings', {
          'values': {for (final k in syncedSettingKeys) k: b[k]},
          'client_updated_at': now.toUtc().toIso8601String(),
        }),
      );
    }
  }

  /// Applies settings restored from the account (last write wins on the
  /// server). Only the synced keys; device choices stay as they are.
  Future<void> applyRemote(Map<String, Object?> values) async {
    final merged = state.toMap()
      ..addAll({
        for (final k in syncedSettingKeys)
          if (values[k] is String) k: values[k]! as String,
      });
    final next = Settings.fromMap(merged);
    state = next;
    final repo = ref.read(settingsRepositoryProvider);
    final now = DateTime.now();
    for (final k in syncedSettingKeys) {
      await repo.put(k, merged[k]!, now);
    }
  }
}

/// Preferences that follow the account across devices. Notification
/// permission, onboarding and analytics consent are per device.
const syncedSettingKeys = [
  'theme_mode',
  'sound',
  'haptics',
  'show_proven_mistakes',
  'auto_cross',
  'show_timer',
  'high_contrast',
];

final settingsProvider = NotifierProvider<SettingsNotifier, Settings>(
  SettingsNotifier.new,
);
