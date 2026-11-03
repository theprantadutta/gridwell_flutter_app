import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/auth/auth_service.dart';
import 'online.dart';
import 'providers.dart';
import 'services.dart';

export '../services/auth/auth_service.dart' show Account, AccountKind, AuthFailure, SignInOutcome;

/// Who the player is: a guest, or signed in with Google, email or Apple.
final accountProvider = StreamProvider<Account>((ref) => ref.watch(authServiceProvider).watch());

/// Sign-in, sign-out and password reset. After any identity change the API
/// session is renewed and progress is reconciled, so nothing played on this
/// device is lost:
/// - a guest who signs up is upgraded in place (same account);
/// - signing in to an existing account pulls its cloud progress, merges it
///   with this device's, and uploads the result.
class AccountActions {
  AccountActions(this._ref);

  final Ref _ref;

  AuthService get _auth => _ref.read(authServiceProvider);
  OnlineSession get _online => _ref.read(onlineSessionProvider);

  Future<SignInOutcome> signInWithGoogle() => _run('google', _auth.signInWithGoogle);

  Future<SignInOutcome> signInWithEmail(String email, String password) =>
      _run('email', () => _auth.signInWithEmail(email, password));

  Future<SignInOutcome> createEmailAccount(String email, String password) =>
      _run('email_create', () => _auth.createEmailAccount(email, password));

  Future<void> sendPasswordReset(String email) => _auth.sendPasswordReset(email);

  /// Pushes anything queued, then signs out. Progress stays on this device;
  /// the game carries on as a new guest.
  Future<void> signOut() async {
    await _online.flushOutbox();
    await _auth.signOut();
    _online.resetSession();
    _ref.read(analyticsProvider).log('sign_out', const {});
    unawaited(_online.ensureSignedIn());
  }

  Future<SignInOutcome> _run(String method, Future<SignInOutcome> Function() signIn) async {
    final outcome = await signIn();
    if (outcome == SignInOutcome.cancelled) return outcome;
    _ref.read(accountOfferProvider.notifier).done();
    _ref.read(analyticsProvider).log('sign_in', {'method': method, 'outcome': outcome.name});
    _online.resetSession();
    if (outcome == SignInOutcome.switched) {
      await _online.restoreFromCloud();
      await _online.uploadAllProgress();
    } else {
      await _online.ensureSignedIn(); // tells the server the account is no longer anonymous
      await _online.flushOutbox();
    }
    return outcome;
  }
}

final accountActionsProvider = Provider((ref) => AccountActions(ref));

/// Book plates solved before the game suggests keeping progress with an
/// account. Never on first launch: only once the player is invested.
const accountOfferAfterSolves = 3;

/// Whether the one-time "keep your progress" offer has been answered.
class AccountOffer extends Notifier<bool> {
  @override
  bool build() => ref.watch(initialAccountOfferDoneProvider);

  void done() {
    if (state) return;
    state = true;
    ref.read(settingsRepositoryProvider).put('account_offer_done', 'true', DateTime.now());
  }
}

/// Overridden in main() with the value saved on this device.
final initialAccountOfferDoneProvider = Provider<bool>((ref) => false);

final accountOfferProvider = NotifierProvider<AccountOffer, bool>(AccountOffer.new);

/// True when the offer should show: a guest, a few plates solved, and not
/// answered before.
final showAccountOfferProvider = Provider<bool>((ref) {
  if (ref.watch(accountOfferProvider)) return false;
  final account = ref.watch(accountProvider).value;
  if (account == null || !account.isGuest) return false;
  final progress = ref.watch(progressProvider).value ?? const {};
  final solved = progress.values.where((p) => p.isSolved && dailyDateOfKey(p.puzzleId) == null).length;
  return solved >= accountOfferAfterSolves;
});
