import 'dart:async';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';

/// Firebase Cloud Messaging: the device token the server needs to send
/// re-engagement and announcement pushes. The daily reminder is local and
/// does not depend on this. Every call is best-effort and never throws.
class PushService {
  FirebaseMessaging? get _fm {
    try {
      return FirebaseMessaging.instance;
    } catch (_) {
      return null; // Firebase not initialized (offline first launch, tests).
    }
  }

  String get platform => defaultTargetPlatform == TargetPlatform.iOS ? 'ios' : 'android';

  // The backend sends with the Firebase Admin SDK, which addresses devices by
  // FCM registration token. firebase_messaging 17 deprecates getToken in favor
  // of register()/onRegistered, which yield an installation id for the newer
  // direct-send API instead; switch both sides together when the server does.
  Future<String?> token() async {
    try {
      // ignore: deprecated_member_use
      return await _fm?.getToken();
    } catch (e) {
      debugPrint('push token unavailable: $e');
      return null;
    }
  }

  /// New tokens after Firebase rotates one.
  // ignore: deprecated_member_use
  Stream<String> get tokenRefreshes => _fm?.onTokenRefresh ?? const Stream.empty();

  /// Pushes that arrive while the app is open (the OS only shows them on its
  /// own while the app is in the background).
  Stream<({String title, String body})> get foregroundMessages =>
      (_fm == null ? const Stream<RemoteMessage>.empty() : FirebaseMessaging.onMessage)
          .where((m) => m.notification != null)
          .map((m) => (title: m.notification!.title ?? 'Gridwell', body: m.notification!.body ?? ''));
}
