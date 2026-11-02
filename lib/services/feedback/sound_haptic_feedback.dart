import 'dart:math' as math;

import 'package:audio_session/audio_session.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_soloud/flutter_soloud.dart';

import 'feedback_service.dart';

/// Haptics plus short sound effects.
///
/// Audio is configured as ambient on both platforms so it never interrupts
/// the player's music or podcast:
/// - iOS: AVAudioSession category Ambient (mixes with others, silenced by the
///   ring/silent switch). flutter_soloud leaves the category untouched, so we
///   set it here before the first sound.
/// - Android: playback never requests audio focus, so other apps keep playing.
class SoundHapticFeedback implements FeedbackService {
  SoundHapticFeedback._();

  static Future<SoundHapticFeedback> create() async {
    final f = SoundHapticFeedback._();
    await f._init();
    return f;
  }

  final _soloud = SoLoud.instance;
  final _sources = <String, AudioSource>{};
  final _rng = math.Random();
  bool _ready = false;
  bool _sound = true;
  bool _haptics = true;
  int _lastCellMs = 0;

  Future<void> _init() async {
    try {
      final session = await AudioSession.instance;
      await session.configure(const AudioSessionConfiguration(
        avAudioSessionCategory: AVAudioSessionCategory.ambient,
        avAudioSessionCategoryOptions: AVAudioSessionCategoryOptions.mixWithOthers,
        avAudioSessionMode: AVAudioSessionMode.defaultMode,
        androidAudioAttributes: AndroidAudioAttributes(
          contentType: AndroidAudioContentType.sonification,
          usage: AndroidAudioUsage.game,
        ),
        // No focus request: other apps keep playing at full volume.
        androidAudioFocusGainType: AndroidAudioFocusGainType.gainTransientMayDuck,
        androidWillPauseWhenDucked: false,
      ));
      await _soloud.init();
      final names = [
        for (var k = 0; k < _scaleNotes; k++) ...['fill_$k', 'cross_$k'],
        'line', 'complete', 'mistake', 'tap',
      ];
      for (final name in names) {
        _sources[name] = await _soloud.loadAsset('assets/sounds/$name.wav');
      }
      _ready = true;
    } catch (e) {
      debugPrint('Sound unavailable: $e');
    }
  }

  /// Notes in the pentatonic scale files (fill_0..7, cross_0..7).
  static const _scaleNotes = 8;

  void _play(String name, {double volume = 0.5, double speed = 1}) {
    if (!_sound || !_ready) return;
    final source = _sources[name];
    if (source == null) return;
    try {
      final handle = _soloud.play(source, volume: volume);
      if (speed != 1) _soloud.setRelativePlaySpeed(handle, speed);
    } catch (_) {}
  }

  /// Scale degree for the n-th cell of a run: up the scale and back down,
  /// so a long drag keeps singing instead of jumping back to the root.
  static int _degree(int index) {
    const span = _scaleNotes - 1;
    final cycle = index % (span * 2);
    return cycle <= span ? cycle : span * 2 - cycle;
  }

  @override
  void cellPlaced({required bool filled, required int index}) {
    // During a very fast drag, notes come at most every 45 ms so a run stays
    // a melody rather than a smear.
    final now = DateTime.now().millisecondsSinceEpoch;
    if (now - _lastCellMs < 45) return;
    _lastCellMs = now;
    // A breath of detune keeps repeated notes from sounding mechanical.
    final detune = 1 + (_rng.nextDouble() - 0.5) * 0.012;
    final degree = _degree(index);
    _play(filled ? 'fill_$degree' : 'cross_$degree', volume: filled ? 0.45 : 0.3, speed: detune);
    if (_haptics) HapticFeedback.selectionClick();
  }

  @override
  void lineCompleted() {
    _play('line', volume: 0.35);
    if (_haptics) HapticFeedback.lightImpact();
  }

  @override
  void puzzleCompleted() {
    _play('complete', volume: 0.5);
    if (_haptics) HapticFeedback.mediumImpact();
  }

  @override
  void mistake() {
    _play('mistake', volume: 0.4);
    if (_haptics) HapticFeedback.heavyImpact();
  }

  @override
  void tap() {
    _play('tap', volume: 0.25);
    if (_haptics) HapticFeedback.selectionClick();
  }

  @override
  set soundEnabled(bool value) => _sound = value;

  @override
  set hapticsEnabled(bool value) => _haptics = value;
}
