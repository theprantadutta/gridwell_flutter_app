import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../config/app_env.dart';

/// How the player is known. Guests have an anonymous Firebase account (or
/// none yet, when Firebase has never been reachable).
enum AccountKind { guest, google, email, apple }

class Account {
  const Account({required this.kind, this.email, this.emailVerified = false});

  static const guest = Account(kind: AccountKind.guest);

  final AccountKind kind;
  final String? email;
  final bool emailVerified;

  bool get isGuest => kind == AccountKind.guest;
}

/// What a sign-in did to the device's identity.
enum SignInOutcome {
  /// The guest account was upgraded in place: same id, same cloud progress.
  linked,

  /// The device now uses a different, existing account. Its cloud progress
  /// should be pulled and merged with this device's.
  switched,

  /// The player closed the Google sheet.
  cancelled,
}

/// A sign-in failure with a message fit to show the player.
class AuthFailure implements Exception {
  const AuthFailure(this.message, {this.code});

  final String message;
  final String? code;

  @override
  String toString() => 'AuthFailure($code): $message';
}

/// Firebase identity. Anonymous by default so the game can talk to the API
/// without asking anything; Google or email/password when the player chooses
/// to keep their progress. Never blocks play: [idToken] returns null when
/// Firebase is unavailable.
class AuthService {
  FirebaseAuth? get _auth {
    try {
      return FirebaseAuth.instance;
    } catch (_) {
      return null; // Firebase not initialized (offline first launch, tests).
    }
  }

  Future<void>? _googleInit;

  Future<String?> idToken() async {
    try {
      final auth = _auth;
      if (auth == null) return null;
      final user = auth.currentUser ?? (await auth.signInAnonymously()).user;
      return await user?.getIdToken();
    } catch (e) {
      debugPrint('auth unavailable: $e');
      return null;
    }
  }

  static Account accountOf(User? user) {
    if (user == null || user.isAnonymous) return Account.guest;
    final providers = user.providerData.map((p) => p.providerId).toSet();
    final kind = providers.contains('google.com')
        ? AccountKind.google
        : providers.contains('apple.com')
            ? AccountKind.apple
            : providers.contains('password')
                ? AccountKind.email
                : AccountKind.guest;
    final email = user.email ??
        user.providerData.map((p) => p.email).firstWhere((e) => e != null, orElse: () => null);
    return Account(kind: kind, email: email, emailVerified: user.emailVerified);
  }

  Account get current => accountOf(_auth?.currentUser);

  /// Emits on sign-in, sign-out and profile changes.
  Stream<Account> watch() {
    final auth = _auth;
    if (auth == null) return Stream.value(Account.guest);
    return auth.userChanges().map(accountOf);
  }

  Future<void> _initGoogle() => _googleInit ??= GoogleSignIn.instance
      .initialize(serverClientId: AppEnv.googleWebClientId)
      .catchError((Object e) {
        _googleInit = null;
        throw e;
      });

  Future<SignInOutcome> signInWithGoogle() async {
    final auth = _requireAuth();
    final OAuthCredential credential;
    try {
      await _initGoogle();
      if (!GoogleSignIn.instance.supportsAuthenticate()) {
        throw const AuthFailure('Google sign-in is not available on this device.');
      }
      final account = await GoogleSignIn.instance.authenticate();
      final idToken = account.authentication.idToken;
      if (idToken == null) throw const AuthFailure('Google did not return an account. Please try again.');
      credential = GoogleAuthProvider.credential(idToken: idToken);
    } on GoogleSignInException catch (e) {
      if (e.code == GoogleSignInExceptionCode.canceled) return SignInOutcome.cancelled;
      debugPrint('google sign-in: $e');
      throw AuthFailure('Google sign-in did not work (${e.code.name}). Please try again.', code: e.code.name);
    }
    return _linkOrSignIn(auth, credential);
  }

  Future<SignInOutcome> signInWithEmail(String email, String password) async {
    final auth = _requireAuth();
    try {
      await auth.signInWithEmailAndPassword(email: email.trim(), password: password);
      return SignInOutcome.switched;
    } on FirebaseAuthException catch (e) {
      throw _friendly(e);
    }
  }

  /// Creates an email/password account. A guest is upgraded in place, so
  /// nothing they have played is lost.
  Future<SignInOutcome> createEmailAccount(String email, String password) async {
    final auth = _requireAuth();
    final user = auth.currentUser;
    try {
      final UserCredential result;
      SignInOutcome outcome;
      if (user != null && user.isAnonymous) {
        result = await user.linkWithCredential(EmailAuthProvider.credential(email: email.trim(), password: password));
        outcome = SignInOutcome.linked;
      } else {
        result = await auth.createUserWithEmailAndPassword(email: email.trim(), password: password);
        outcome = SignInOutcome.switched;
      }
      unawaited(result.user?.sendEmailVerification().catchError((Object _) {}));
      return outcome;
    } on FirebaseAuthException catch (e) {
      throw _friendly(e);
    }
  }

  Future<void> sendPasswordReset(String email) async {
    try {
      await _requireAuth().sendPasswordResetEmail(email: email.trim());
    } on FirebaseAuthException catch (e) {
      throw _friendly(e);
    }
  }

  /// Signs out of Google and Firebase. The next [idToken] creates a fresh
  /// guest account.
  Future<void> signOut() async {
    try {
      if (_googleInit != null) await GoogleSignIn.instance.signOut();
    } catch (_) {}
    await _auth?.signOut();
  }

  FirebaseAuth _requireAuth() {
    final auth = _auth;
    if (auth == null) throw const AuthFailure('Signing in needs a connection. Please try again later.');
    return auth;
  }

  /// A guest links the credential (same account, upgraded). If that Google
  /// account already belongs to a Gridwell player, sign in to it instead.
  Future<SignInOutcome> _linkOrSignIn(FirebaseAuth auth, AuthCredential credential) async {
    final user = auth.currentUser;
    try {
      if (user != null && user.isAnonymous) {
        try {
          await user.linkWithCredential(credential);
          return SignInOutcome.linked;
        } on FirebaseAuthException catch (e) {
          if (e.code != 'credential-already-in-use' && e.code != 'email-already-in-use') rethrow;
          await auth.signInWithCredential(e.credential ?? credential);
          return SignInOutcome.switched;
        }
      }
      await auth.signInWithCredential(credential);
      return SignInOutcome.switched;
    } on FirebaseAuthException catch (e) {
      throw _friendly(e);
    }
  }

  static AuthFailure _friendly(FirebaseAuthException e) {
    debugPrint('firebase auth: ${e.code} ${e.message}');
    final message = switch (e.code) {
      'invalid-email' => 'That email address does not look right.',
      'user-not-found' || 'wrong-password' || 'invalid-credential' || 'INVALID_LOGIN_CREDENTIALS' =>
        'That email and password do not match an account.',
      'email-already-in-use' => 'An account already uses this email. Sign in instead.',
      'credential-already-in-use' => 'This account is already in use by another player.',
      'weak-password' => 'Please choose a password of at least 6 characters.',
      'user-disabled' => 'This account has been turned off.',
      'too-many-requests' => 'Too many tries. Please wait a little and try again.',
      'network-request-failed' => 'No connection. Please try again when you are online.',
      'operation-not-allowed' || 'admin-restricted-operation' =>
        'This way of signing in is not turned on yet.',
      'account-exists-with-different-credential' =>
        'This email already has an account with a different sign-in. Use that one.',
      _ => 'Something went wrong (${e.code}). Please try again.',
    };
    return AuthFailure(message, code: e.code);
  }
}
