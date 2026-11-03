import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/notifications/notification_service.dart';
import 'online.dart';
import 'settings.dart';

/// Overridden in main() with the initialized service.
final notificationServiceProvider = Provider<NotificationService>((ref) => NotificationService());

/// The 7pm daily reminder: one pending local notification, rescheduled on
/// every app start and resume and after a daily is solved. Skips today when
/// today's daily is already solved.
class ReminderScheduler {
  ReminderScheduler(this._ref);

  final Ref _ref;
  static const hour = 19;

  Future<void> reschedule() async {
    final service = _ref.read(notificationServiceProvider);
    final settings = _ref.read(settingsProvider);
    if (!settings.dailyReminder || !settings.notificationsAsked || !await service.permitted) {
      await service.cancelReminder();
      return;
    }
    final now = DateTime.now();
    final results = _ref.read(dailyResultsProvider).value ?? const {};
    final todaySolved = results[localDateString(now)]?.solved ?? false;
    var day = DateTime(now.year, now.month, now.day);
    if (todaySolved || now.hour >= hour) day = day.add(const Duration(days: 1));
    final key = localDateString(day);
    final puzzle = dailyFor(_ref, key);
    if (puzzle == null) {
      await service.cancelReminder();
      return;
    }
    await service.scheduleReminder(
      DateTime(day.year, day.month, day.day, hour),
      title: "Today's leaf is waiting",
      body: '${puzzle.name}, ${puzzle.width} × ${puzzle.height}. A few quiet minutes.',
    );
  }

  /// After the first solve, if the player says yes: ask the OS, remember the
  /// answer, schedule.
  Future<bool> optIn() async {
    final granted = await _ref.read(notificationServiceProvider).requestPermission();
    await _ref.read(settingsProvider.notifier).update((s) => s.copyWith(notificationsAsked: true, dailyReminder: granted));
    unawaited(reschedule());
    return granted;
  }

  Future<void> decline() =>
      _ref.read(settingsProvider.notifier).update((s) => s.copyWith(notificationsAsked: true, dailyReminder: false));
}

final reminderSchedulerProvider = Provider((ref) => ReminderScheduler(ref));
