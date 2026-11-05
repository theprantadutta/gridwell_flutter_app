import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/store/app_review_service.dart';
import '../services/store/app_update_service.dart';
import 'board_controller.dart';
import 'providers.dart';
import 'settings.dart';

export '../services/store/app_update_service.dart' show UpdateCheck;

final appUpdateServiceProvider = Provider((ref) => AppUpdateService());
final appReviewServiceProvider = Provider((ref) => AppReviewService());

/// True once a Play update has downloaded and only needs a restart.
class UpdateReady extends Notifier<bool> {
  @override
  bool build() => false;

  /// Runs once the first screen is up, and from Settings with [manual].
  Future<UpdateCheck> check({bool manual = false}) {
    final declined = ref.read(settingsProvider).updateDeclinedMs;
    return ref
        .read(appUpdateServiceProvider)
        .check(
          manual: manual,
          sinceDeclined: declined == 0
              ? null
              : DateTime.now().difference(
                  DateTime.fromMillisecondsSinceEpoch(declined),
                ),
          onDeclined: () => ref
              .read(settingsProvider.notifier)
              .update(
                (s) => s.copyWith(
                  updateDeclinedMs: DateTime.now().millisecondsSinceEpoch,
                ),
              ),
          onReady: (ready) => state = ready,
        );
  }

  Future<void> install() => ref.read(appUpdateServiceProvider).install();
}

final updateReadyProvider = NotifierProvider<UpdateReady, bool>(
  UpdateReady.new,
);

/// Asks for a review at a high point, after the completion scene has played.
class ReviewPrompter {
  ReviewPrompter(this._ref);

  final Ref _ref;

  Future<void> onCompletion(CompletionResult r) async {
    final highPoint =
        r.completedCollection ||
        r.beatSizeBest ||
        (r.outcome.isPersonalBest && !r.outcome.isFirstSolve);
    if (!highPoint) return;
    final now = DateTime.now();
    final solves =
        (await _ref.read(progressRepositoryProvider).all()).values
            .map((p) => p.solvedAt)
            .nonNulls
            .toList()
          ..sort();
    final asked = _ref.read(settingsProvider).reviewAskedMs;
    final ask = shouldAskForReview(
      solved: solves.length,
      firstSolvedAt: solves.firstOrNull,
      lastAskedAt: asked == 0
          ? null
          : DateTime.fromMillisecondsSinceEpoch(asked),
      now: now,
    );
    final service = _ref.read(appReviewServiceProvider);
    if (!ask || !await service.isAvailable()) return;
    // Stamp first: better to skip a moment than to ask twice in a row.
    await _ref
        .read(settingsProvider.notifier)
        .update((s) => s.copyWith(reviewAskedMs: now.millisecondsSinceEpoch));
    unawaited(
      Future<void>.delayed(const Duration(seconds: 4), service.request),
    );
  }
}

final reviewPrompterProvider = Provider((ref) => ReviewPrompter(ref));
