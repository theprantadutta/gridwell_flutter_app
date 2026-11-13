import 'dart:ui' show Rect;

import 'package:share_plus/share_plus.dart';

import '../crash/crash_reporter.dart';

/// Opens the system share sheet.
abstract interface class ShareService {
  /// Shares [text]. [origin] anchors the sheet on iPad (required there).
  /// Returns false if the sheet could not open.
  Future<bool> shareText(String text, {String? subject, Rect? origin});
}

class SharePlusService implements ShareService {
  const SharePlusService();

  @override
  Future<bool> shareText(String text, {String? subject, Rect? origin}) async {
    try {
      final result = await SharePlus.instance.share(
        ShareParams(text: text, subject: subject, sharePositionOrigin: origin),
      );
      return result.status != ShareResultStatus.unavailable;
    } catch (e, st) {
      CrashReports.instance.recordError(e, st, reason: 'share app');
      return false;
    }
  }
}
