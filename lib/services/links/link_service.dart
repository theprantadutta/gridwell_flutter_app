import 'package:url_launcher/url_launcher.dart';

import '../crash/crash_reporter.dart';

/// Opens web links outside the app.
abstract interface class LinkService {
  /// Opens [uri] in the browser. False if nothing could open it.
  Future<bool> open(Uri uri);
}

class UrlLauncherLinkService implements LinkService {
  const UrlLauncherLinkService();

  @override
  Future<bool> open(Uri uri) async {
    try {
      return await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (e, st) {
      CrashReports.instance.recordError(e, st, reason: 'open link');
      return false;
    }
  }
}
