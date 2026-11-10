import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/foundation.dart';

import 'analytics_service.dart';

/// Firebase Analytics behind [AnalyticsService]. Never throws.
class FirebaseAnalyticsService implements AnalyticsService {
  FirebaseAnalyticsService(this._fa);

  final FirebaseAnalytics _fa;

  @override
  Future<void> log(String event, [Map<String, Object> params = const {}]) async {
    try {
      await _fa.logEvent(name: event, parameters: params.isEmpty ? null : params);
    } catch (e) {
      debugPrint('analytics $event failed: $e');
    }
  }

  /// Firebase batches and uploads on its own schedule; on backgrounding the
  /// SDK flushes what it has. Nothing extra is needed here, but the hook
  /// stays so another backend can flush explicitly.
  @override
  Future<void> flush() async {}

  @override
  Future<void> setEnabled(bool enabled) async {
    try {
      await _fa.setAnalyticsCollectionEnabled(enabled);
    } catch (_) {}
  }

  @override
  Future<void> screen(String name) async {
    try {
      await _fa.logScreenView(screenName: name, screenClass: name);
    } catch (e) {
      debugPrint('analytics screen $name failed: $e');
    }
  }

  @override
  Future<void> setUserId(String? id) async {
    try {
      await _fa.setUserId(id: id);
    } catch (_) {}
  }

  @override
  Future<void> setUserProperty(String name, String? value) async {
    try {
      await _fa.setUserProperty(name: name, value: value);
    } catch (_) {}
  }
}
