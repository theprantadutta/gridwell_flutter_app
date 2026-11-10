import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'account.dart';
import 'services.dart';

/// Keeps analytics and crash reports in step with who is playing and where.
///
/// * User: the pseudonymous Firebase uid on both, plus `account_kind` and
///   entitlement user properties for segmenting. Never the email.
/// * Screen: a `screen_view` per route, and the current screen as a crash key
///   so every report says where it happened.
class Telemetry {
  Telemetry(this._ref) {
    _ref.listen(accountProvider, (_, next) {
      final account = next.value;
      if (account == null) return;
      final analytics = _ref.read(analyticsProvider);
      final crash = _ref.read(crashReporterProvider);
      analytics.setUserId(account.uid);
      analytics.setUserProperty('account_kind', account.kind.name);
      crash.setUserId(account.uid);
      crash.setKey('account_kind', account.kind.name);
    }, fireImmediately: true);
    _ref.listen(entitlementsProvider, (_, e) {
      final plan = e.premium ? 'premium' : (e.removeAds ? 'remove_ads' : 'free');
      _ref.read(analyticsProvider).setUserProperty('plan', plan);
      _ref.read(crashReporterProvider).setKey('plan', plan);
    }, fireImmediately: true);
  }

  final Ref _ref;
  String? _lastScreen;

  /// Called on every navigation with the matched route pattern, such as
  /// `/play/:id`. Logs `board`, `collection`, `contents`... once per change.
  void route(String pattern, {String? puzzleId}) {
    final name = screenName(pattern);
    if (name == _lastScreen) return;
    _lastScreen = name;
    _ref.read(analyticsProvider).screen(name);
    final crash = _ref.read(crashReporterProvider);
    crash.setKey('screen', name);
    if (puzzleId != null) crash.setKey('puzzle_id', puzzleId);
    crash.log('screen $name${puzzleId == null ? '' : ' $puzzleId'}');
  }

  /// `/play/:id` -> `board`, `/account/email` -> `account_email`, `/` -> `home`.
  static String screenName(String pattern) {
    if (pattern.startsWith('/play')) return 'board';
    final parts = pattern.split('/').where((p) => p.isNotEmpty && !p.startsWith(':')).toList();
    return parts.isEmpty ? 'home' : parts.join('_');
  }
}

final telemetryProvider = Provider((ref) => Telemetry(ref));
