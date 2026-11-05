import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:in_app_update/in_app_update.dart';

/// What a check found.
enum UpdateCheck { upToDate, offered, ready, failed }

/// How an available Play update is offered.
enum UpdateFlow { none, flexible, immediate }

/// Pure, so it can be tested. Flexible is the default: Play downloads while
/// the player keeps solving. Only a release published with a high update
/// priority gets the blocking flow (a Play Console upload is priority 0).
UpdateFlow decideUpdateFlow({
  required bool updateAvailable,
  required int priority,
  required bool immediateAllowed,
  required bool flexibleAllowed,
  required Duration? sinceDeclined,
}) {
  if (!updateAvailable) return UpdateFlow.none;
  if (priority >= 4 && immediateAllowed) return UpdateFlow.immediate;
  if (sinceDeclined != null && sinceDeclined < const Duration(hours: 24)) {
    return UpdateFlow.none;
  }
  return flexibleAllowed ? UpdateFlow.flexible : UpdateFlow.none;
}

/// Play in-app updates. Android only, and only in a build installed from
/// Play: anywhere else the check fails quietly. Never throws, so a failed
/// check can never get in the way of playing.
class AppUpdateService {
  StreamSubscription<InstallStatus>? _install;
  bool _checked = false;

  /// One automatic check per process; [manual] is the player asking, so it
  /// always runs and ignores an earlier decline. [onReady] says a download
  /// only needs a restart.
  Future<UpdateCheck> check({
    bool manual = false,
    required Duration? sinceDeclined,
    required VoidCallback onDeclined,
    required ValueChanged<bool> onReady,
  }) async {
    if (kDebugMode || defaultTargetPlatform != TargetPlatform.android) {
      return UpdateCheck.failed;
    }
    if (_checked && !manual) return UpdateCheck.upToDate;
    _checked = true;
    try {
      final info = await InAppUpdate.checkForUpdate().timeout(
        const Duration(seconds: 5),
      );
      // A download from an earlier session finished while the app was closed.
      if (info.installStatus == InstallStatus.downloaded) {
        onReady(true);
        return UpdateCheck.ready;
      }
      // Already downloading from an earlier offer.
      if (info.updateAvailability ==
          UpdateAvailability.developerTriggeredUpdateInProgress) {
        return UpdateCheck.offered;
      }
      final available =
          info.updateAvailability == UpdateAvailability.updateAvailable;
      final flow = decideUpdateFlow(
        updateAvailable: available,
        priority: info.updatePriority,
        immediateAllowed: info.immediateUpdateAllowed,
        flexibleAllowed: info.flexibleUpdateAllowed,
        sinceDeclined: manual ? null : sinceDeclined,
      );
      switch (flow) {
        case UpdateFlow.none:
          return available ? UpdateCheck.failed : UpdateCheck.upToDate;
        case UpdateFlow.immediate:
          await InAppUpdate.performImmediateUpdate();
        case UpdateFlow.flexible:
          _install ??= InAppUpdate.installUpdateListener.listen((status) {
            if (status == InstallStatus.downloaded) {
              onReady(true);
            } else if (status == InstallStatus.failed ||
                status == InstallStatus.canceled) {
              onReady(false);
            }
          }, onError: (Object e) => debugPrint('update status failed: $e'));
          final result = await InAppUpdate.startFlexibleUpdate();
          if (result == AppUpdateResult.userDeniedUpdate) onDeclined();
      }
      return UpdateCheck.offered;
    } catch (e) {
      debugPrint('update check failed: $e');
      return UpdateCheck.failed;
    }
  }

  /// Installs a finished download; Play restarts the app.
  Future<void> install() async {
    try {
      await InAppUpdate.completeFlexibleUpdate();
    } catch (e) {
      debugPrint('update install failed: $e');
    }
  }
}
