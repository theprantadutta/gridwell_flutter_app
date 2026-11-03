import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

/// Thin client for the Gridwell API. Every call is optional enrichment: it
/// returns null on any failure (offline, timeout, server error) and never
/// throws, so callers treat "no network" as an ordinary state.
class ApiClient {
  ApiClient({http.Client? client, String? baseUrl})
      : _http = client ?? http.Client(),
        baseUrl = baseUrl ?? const String.fromEnvironment('GRIDWELL_API', defaultValue: 'https://gridwell.pranta.dev/api/v1');

  final http.Client _http;
  final String baseUrl;

  /// Bearer token from [authWithFirebase].
  String? token;

  static const _timeout = Duration(seconds: 8);

  Map<String, String> get _headers => {
        'Content-Type': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      };

  Future<Object?> _send(String method, String path, {Object? body, Map<String, String>? query}) async {
    try {
      final uri = Uri.parse('$baseUrl$path').replace(queryParameters: query);
      final req = http.Request(method, uri)..headers.addAll(_headers);
      if (body != null) req.body = jsonEncode(body);
      final res = await http.Response.fromStream(await _http.send(req).timeout(_timeout));
      if (res.statusCode == 401) token = null;
      if (res.statusCode < 200 || res.statusCode >= 300) return null;
      return res.body.isEmpty ? <String, Object?>{} : jsonDecode(res.body);
    } catch (_) {
      return null;
    }
  }

  /// Exchanges a Firebase ID token for an API token. Returns the user json.
  Future<Map<String, Object?>?> authWithFirebase(String idToken, int tzOffsetMinutes) async {
    final r = await _send('POST', '/auth/firebase',
        body: {'firebase_token': idToken, 'time_zone_offset_minutes': tzOffsetMinutes});
    if (r is! Map<String, Object?>) return null;
    token = r['access_token'] as String?;
    return r['user'] as Map<String, Object?>?;
  }

  Future<List<Map<String, Object?>>?> upcomingDailies(String localDate, int tzOffsetMinutes, {int days = 7}) async {
    final r = await _send('GET', '/daily/upcoming',
        query: {'date': localDate, 'tz_offset_minutes': '$tzOffsetMinutes', 'days': '$days'});
    return r is List ? r.cast<Map<String, Object?>>() : null;
  }

  Future<List<Map<String, Object?>>?> dailyRange(String from, String to) async {
    final r = await _send('GET', '/daily/range', query: {'from': from, 'to': to});
    return r is List ? r.cast<Map<String, Object?>>() : null;
  }

  Future<Map<String, Object?>?> completeDaily(String date, int timeMs, String clientLocalDate) async {
    final r = await _send('POST', '/daily/$date/complete',
        body: {'time_ms': timeMs, 'client_local_date': clientLocalDate});
    return r is Map<String, Object?> ? r : null;
  }

  Future<Map<String, Object?>?> dailyLeaderboard(String date, {int limit = 20}) async {
    final r = await _send('GET', '/leaderboards/daily/$date', query: {'limit': '$limit'});
    return r is Map<String, Object?> ? r : null;
  }

  /// Returns the ack `{accepted: [...], rejected: [{id, reason}]}`.
  Future<Map<String, Object?>?> syncPush(Map<String, Object?> body) async {
    final r = await _send('POST', '/sync/push', body: body);
    return r is Map<String, Object?> ? r : null;
  }

  Future<Map<String, Object?>?> syncPull() async {
    final r = await _send('GET', '/sync/pull');
    return r is Map<String, Object?> ? r : null;
  }

  /// Returns `{verified, status, product_id, entitlements, ...}`.
  Future<Map<String, Object?>?> verifyPurchase({
    required String platform,
    required String productId,
    String? purchaseToken,
    String? signedTransaction,
  }) async {
    final r = await _send('POST', '/purchases/verify', body: {
      'platform': platform,
      'product_id': productId,
      'purchase_token': ?purchaseToken,
      'signed_transaction': ?signedTransaction,
    });
    return r is Map<String, Object?> ? r : null;
  }

  Future<bool> registerToken(String fcmToken, String platform, int tzOffsetMinutes) async =>
      await _send('POST', '/users/register-token',
          body: {'token': fcmToken, 'platform': platform, 'time_zone_offset_minutes': tzOffsetMinutes}) !=
      null;

  /// Deletes the account and all server-side data (and the Firebase user).
  Future<bool> deleteAccount() async => await _send('DELETE', '/users/me') != null;

  Future<Map<String, Object?>?> updateProfile({String? penName, bool? notificationsEnabled}) async {
    final r = await _send('PATCH', '/users/me', body: {
      'pen_name': ?penName,
      'notifications_enabled': ?notificationsEnabled,
    });
    return r is Map<String, Object?> ? r : null;
  }
}
