import 'dart:ui' show Color;

import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

/// Local notifications: the 7pm daily reminder. Scheduled on the device in
/// the player's own timezone, so it works with no connection at all.
class NotificationService {
  final _plugin = FlutterLocalNotificationsPlugin();
  bool _ready = false;

  static const _reminderId = 7;
  static const _channel = AndroidNotificationDetails(
    'gridwell_daily',
    'Daily reminder',
    channelDescription: "A quiet note when today's puzzle is still open",
    importance: Importance.defaultImportance,
    priority: Priority.defaultPriority,
    icon: '@drawable/ic_notification',
    color: Color(0xFF3C740D), // Tally accent (light); matches res/values/notification_colors.xml
  );

  Future<void> initialize() async {
    try {
      tzdata.initializeTimeZones();
      final local = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(local.identifier));
      await _plugin.initialize(
        settings: const InitializationSettings(
          android: AndroidInitializationSettings('@drawable/ic_notification'),
          iOS: DarwinInitializationSettings(
            requestAlertPermission: false,
            requestBadgePermission: false,
            requestSoundPermission: false,
          ),
        ),
      );
      _ready = true;
    } catch (e) {
      debugPrint('notifications unavailable: $e');
    }
  }

  /// Asks the OS for permission (Android 13+, iOS). Returns true if granted.
  Future<bool> requestPermission() async {
    if (!_ready) return false;
    try {
      final android = _plugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
      if (android != null) return await android.requestNotificationsPermission() ?? false;
      final ios = _plugin.resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>();
      if (ios != null) return await ios.requestPermissions(alert: true, sound: true) ?? false;
    } catch (e) {
      debugPrint('notification permission failed: $e');
    }
    return false;
  }

  Future<bool> get permitted async {
    if (!_ready) return false;
    try {
      final android = _plugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
      if (android != null) return await android.areNotificationsEnabled() ?? false;
      final ios = _plugin.resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>();
      if (ios != null) return (await ios.checkPermissions())?.isEnabled ?? false;
    } catch (_) {}
    return false;
  }

  /// Replaces any pending reminder with one at [when] (local time).
  Future<void> scheduleReminder(DateTime when, {required String title, required String body}) async {
    if (!_ready) return;
    try {
      await _plugin.cancel(id: _reminderId);
      await _plugin.zonedSchedule(
        id: _reminderId,
        scheduledDate: tz.TZDateTime.from(when, tz.local),
        notificationDetails: const NotificationDetails(android: _channel, iOS: DarwinNotificationDetails()),
        // Inexact is fine for a gentle reminder and needs no exact-alarm permission.
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        title: title,
        body: body,
        payload: '/daily',
      );
    } catch (e) {
      debugPrint('reminder scheduling failed: $e');
    }
  }

  /// Shows a notification right away (a push that arrived while the app was open).
  Future<void> showNow({required String title, required String body}) async {
    if (!_ready) return;
    try {
      await _plugin.show(
        id: DateTime.now().millisecondsSinceEpoch ~/ 1000 % 100000 + 100,
        title: title,
        body: body,
        notificationDetails: const NotificationDetails(android: _channel, iOS: DarwinNotificationDetails()),
      );
    } catch (e) {
      debugPrint('notification failed: $e');
    }
  }

  Future<void> cancelReminder() async {
    if (!_ready) return;
    try {
      await _plugin.cancel(id: _reminderId);
    } catch (_) {}
  }
}
