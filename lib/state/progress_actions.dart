import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'online.dart';
import 'providers.dart';

/// Bulk progress operations used by Settings.
class ProgressActions {
  ProgressActions(this._ref);

  final Ref _ref;

  /// Clears every solve and every board in progress on this device.
  Future<void> resetAll() async {
    await _ref.read(progressRepositoryProvider).clearAll();
    await _ref.read(boardRepositoryProvider).clearAll();
  }
}

/// Outcome of "Delete my data".
enum DeleteOutcome { deleted, deletedLocallyOnly }

extension AccountDeletion on ProgressActions {
  /// Deletes the account on the server (when reachable) and everything on
  /// this device: progress, boards, daily results and queued sync rows.
  /// Purchases belong to the store account and can be restored afterwards.
  Future<DeleteOutcome> deleteEverything() async {
    final ref = _ref;
    final online = ref.read(onlineSessionProvider);
    var serverDeleted = false;
    if (await online.ensureSignedIn()) {
      serverDeleted = await ref.read(apiClientProvider).deleteAccount();
    }
    await resetAll();
    final db = ref.read(databaseProvider);
    await db.delete(db.dailyResults).go();
    await db.delete(db.outbox).go();
    try {
      await ref.read(authServiceProvider).signOut();
    } catch (_) {}
    // Forget the deleted account's session and pen name; the next online
    // call starts a fresh guest.
    online.resetSession();
    return serverDeleted ? DeleteOutcome.deleted : DeleteOutcome.deletedLocallyOnly;
  }
}

final progressActionsProvider = Provider((ref) => ProgressActions(ref));
