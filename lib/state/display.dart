import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/display/display_rate_service.dart';
import 'settings.dart';

export '../services/display/display_rate_service.dart' show DisplayRates;

/// Swapped for the `refresh_rate` plugin in main().
final displayRateServiceProvider = Provider<DisplayRateService>((ref) => const NoopDisplayRateService());

/// "Smooth motion": keeps the display's refresh rate in step with the
/// player's setting, and knows what the display can do.
///
/// The state is the latest reading (null until the first read). The request
/// is re-sent on start, whenever the setting changes and on every resume,
/// so a task switch never leaves the app quietly back at 60 Hz.
class DisplayRateController extends Notifier<DisplayRates?> {
  @override
  DisplayRates? build() {
    ref.listen(settingsProvider.select((s) => s.highRefreshRate), (_, _) => unawaited(apply()));
    return null;
  }

  DisplayRateService get _service => ref.read(displayRateServiceProvider);

  /// Sends the current preference to the display, then reads back what it did.
  Future<void> apply() async {
    await _service.setHigh(ref.read(settingsProvider).highRefreshRate);
    await refresh();
  }

  /// Reads what the display is doing right now.
  Future<void> refresh() async {
    final rates = await _service.read();
    if (rates != null) state = rates;
  }
}

final displayRateProvider = NotifierProvider<DisplayRateController, DisplayRates?>(DisplayRateController.new);
