import 'package:flutter/foundation.dart';
import 'package:in_app_review/in_app_review.dart';

/// Whether this is a good moment to ask. Play and the App Store cap the sheet
/// to a few per year and skip the rest silently, so it waits for someone who
/// has played enough to have an opinion, and asks rarely. Pure, for testing.
bool shouldAskForReview({
  required int solved,
  required DateTime? firstSolvedAt,
  required DateTime? lastAskedAt,
  required DateTime now,
}) {
  if (solved < 10 || firstSolvedAt == null) return false;
  if (now.difference(firstSolvedAt) < const Duration(days: 2)) return false;
  return lastAskedAt == null ||
      now.difference(lastAskedAt) >= const Duration(days: 60);
}

/// The platform's review sheet. The platform decides whether it really shows
/// and never says what was rated. On Android it needs a Play install. Never
/// throws.
class AppReviewService {
  Future<bool> isAvailable() async {
    try {
      return await InAppReview.instance.isAvailable();
    } catch (e) {
      debugPrint('review check failed: $e');
      return false;
    }
  }

  Future<void> request() async {
    try {
      await InAppReview.instance.requestReview();
    } catch (e) {
      debugPrint('review request failed: $e');
    }
  }
}
