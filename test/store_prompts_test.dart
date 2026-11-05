import 'package:flutter_test/flutter_test.dart';
import 'package:gridwell_flutter_app/services/store/app_review_service.dart';
import 'package:gridwell_flutter_app/services/store/app_update_service.dart';

void main() {
  group('review gate', () {
    final now = DateTime(2026, 12, 1);
    bool ask({
      int solved = 10,
      Duration? playing = const Duration(days: 2),
      Duration? sinceAsked,
    }) => shouldAskForReview(
      solved: solved,
      firstSolvedAt: playing == null ? null : now.subtract(playing),
      lastAskedAt: sinceAsked == null ? null : now.subtract(sinceAsked),
      now: now,
    );

    test(
      'asks a player with enough solves and days',
      () => expect(ask(), isTrue),
    );
    test('waits for 10 solves', () => expect(ask(solved: 9), isFalse));
    test(
      'never on the first days',
      () => expect(ask(playing: const Duration(days: 1)), isFalse),
    );
    test('needs a first solve', () => expect(ask(playing: null), isFalse));
    test('leaves 60 days between asks', () {
      expect(ask(sinceAsked: const Duration(days: 59)), isFalse);
      expect(ask(sinceAsked: const Duration(days: 60)), isTrue);
    });
  });

  group('update flow', () {
    UpdateFlow flow({
      bool available = true,
      int priority = 0,
      bool immediate = true,
      bool flexible = true,
      Duration? declined,
    }) => decideUpdateFlow(
      updateAvailable: available,
      priority: priority,
      immediateAllowed: immediate,
      flexibleAllowed: flexible,
      sinceDeclined: declined,
    );

    test(
      'nothing without an update',
      () => expect(flow(available: false), UpdateFlow.none),
    );
    test('flexible by default', () => expect(flow(), UpdateFlow.flexible));
    test(
      'blocking only at high priority',
      () => expect(flow(priority: 4), UpdateFlow.immediate),
    );
    test('a decline is left alone for a day', () {
      expect(flow(declined: const Duration(hours: 23)), UpdateFlow.none);
      expect(flow(declined: const Duration(hours: 24)), UpdateFlow.flexible);
    });
    test('an urgent release ignores a decline', () {
      expect(
        flow(priority: 5, declined: const Duration(hours: 1)),
        UpdateFlow.immediate,
      );
    });
    test(
      'never blocks for a routine release',
      () => expect(flow(flexible: false), UpdateFlow.none),
    );
  });
}
