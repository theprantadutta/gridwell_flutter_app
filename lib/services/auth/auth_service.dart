import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

/// Anonymous Firebase identity, used only to talk to the Gridwell API.
/// Returns null whenever Firebase is unavailable; the game never waits on it.
class AuthService {
  Future<String?> idToken() async {
    try {
      final auth = FirebaseAuth.instance;
      final user = auth.currentUser ?? (await auth.signInAnonymously()).user;
      return await user?.getIdToken();
    } catch (e) {
      debugPrint('auth unavailable: $e');
      return null;
    }
  }
}
