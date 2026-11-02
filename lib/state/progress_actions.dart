import 'package:flutter_riverpod/flutter_riverpod.dart';

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

final progressActionsProvider = Provider((ref) => ProgressActions(ref));
