import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../services/links/link_service.dart';
import '../services/share/share_service.dart';

/// "1.0.0 (214)" for the settings footer.
final appVersionProvider = FutureProvider<String>((ref) async {
  final info = await PackageInfo.fromPlatform();
  return '${info.version} (${info.buildNumber})';
});

/// Version and build, separately, for the About page.
final appInfoProvider = FutureProvider<({String version, String build})>((ref) async {
  final info = await PackageInfo.fromPlatform();
  return (version: info.version, build: info.buildNumber);
});

/// Opens web links in the browser (the About page's portfolio link).
final linkServiceProvider = Provider<LinkService>((ref) => const UrlLauncherLinkService());

/// The system share sheet (Settings > Share Gridwell).
final shareServiceProvider = Provider<ShareService>((ref) => const SharePlusService());

/// Gridwell on Google Play, for sharing.
const playStoreUrl = 'https://play.google.com/store/apps/details?id=com.pranta.gridwell';
