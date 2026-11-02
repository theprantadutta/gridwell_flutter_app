/// Haptic and audio feedback for board events.
///
/// Implementations must never block or throw: feedback is decoration.
abstract interface class FeedbackService {
  /// A cell changed during a stroke. [index] is the cell's position within
  /// the stroke (0 for the first), used to vary pitch so a dragged run does
  /// not sound like a loop.
  void cellPlaced({required bool filled, required int index});

  /// A row or column now matches its clue.
  void lineCompleted();

  /// The puzzle is solved.
  void puzzleCompleted();

  /// A proven mistake appeared.
  void mistake();

  /// Mode switch, undo and other small taps.
  void tap();

  set soundEnabled(bool value);
  set hapticsEnabled(bool value);
}

class SilentFeedback implements FeedbackService {
  @override
  void cellPlaced({required bool filled, required int index}) {}
  @override
  void lineCompleted() {}
  @override
  void puzzleCompleted() {}
  @override
  void mistake() {}
  @override
  void tap() {}
  @override
  set soundEnabled(bool value) {}
  @override
  set hapticsEnabled(bool value) {}
}
