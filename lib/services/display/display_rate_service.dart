import 'package:flutter/foundation.dart';
import 'package:refresh_rate/refresh_rate.dart';

import '../crash/crash_reporter.dart';

/// What the display is doing, read from the platform. Rates are in Hz; 0
/// means the platform did not say.
class DisplayRates {
  const DisplayRates({
    required this.currentHz,
    required this.maxHz,
    required this.supportedHz,
    this.lowPower = false,
    this.warm = false,
  });

  final double currentHz;
  final double maxHz;
  final List<double> supportedHz;

  /// Battery saver is on: the system holds the standard rate whatever we ask.
  final bool lowPower;

  /// The device is warm and may hold a lower rate to cool down.
  final bool warm;

  /// A screen that can only do one rate has nothing to offer.
  bool get supportsHighRate => maxHz > 61 || supportedHz.where((r) => r > 61).isNotEmpty;
}

/// Asks the display for its highest refresh rate, or hands the choice back
/// to the system. Flutter never does this on its own, so a 120 Hz phone runs
/// the app at 60 Hz unless asked.
abstract interface class DisplayRateService {
  /// Requests the highest rate ([high]) or the system default. A request is
  /// a preference the system may decline (battery saver, heat).
  Future<void> setHigh(bool high);

  /// What the display is doing now, or null if it could not be read.
  Future<DisplayRates?> read();
}

/// The `refresh_rate` plugin. Control works on Android 6+; on iOS the
/// display is ProMotion-driven (Info.plist `CADisableMinimumFrameDurationOnPhone`)
/// and the plugin only reports rates.
class RefreshRateDisplayService implements DisplayRateService {
  const RefreshRateDisplayService();

  @override
  Future<void> setHigh(bool high) async {
    try {
      final result = high ? await RefreshRate.preferMax() : await RefreshRate.disable();
      if (result.status == RequestStatus.failed) {
        debugPrint('refresh rate request failed: ${result.message}');
      }
    } catch (e, st) {
      // Unsupported hardware is not a failure; anything else is worth a look.
      CrashReports.instance.recordError(e, st, reason: 'refresh rate request');
    }
  }

  @override
  Future<DisplayRates?> read() async {
    try {
      final info = await RefreshRate.refresh();
      return DisplayRates(
        currentHz: info.currentRate,
        maxHz: info.maxRate,
        supportedHz: info.supportedRates,
        lowPower: info.isLowPowerMode ?? false,
        warm: info.thermalState == ThermalState.serious || info.thermalState == ThermalState.critical,
      );
    } catch (e) {
      debugPrint('display info unavailable: $e');
      return null;
    }
  }
}

/// Does nothing. Tests, and platforms without the plugin.
class NoopDisplayRateService implements DisplayRateService {
  const NoopDisplayRateService();

  @override
  Future<void> setHigh(bool high) async {}

  @override
  Future<DisplayRates?> read() async => null;
}
