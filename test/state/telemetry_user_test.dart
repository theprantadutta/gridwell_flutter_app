import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gridwell_flutter_app/services/analytics/analytics_service.dart';
import 'package:gridwell_flutter_app/state/account.dart';
import 'package:gridwell_flutter_app/state/services.dart';
import 'package:gridwell_flutter_app/state/telemetry.dart';

class Rec extends MemoryAnalytics {
  final props = <String>[];
  @override
  Future<void> setUserProperty(String name, String? value) async => props.add('$name=$value');
  @override
  Future<void> setUserId(String? id) async => props.add('id=$id');
}

void main() {
  test('telemetry links the uid, account kind and plan once the account resolves', () async {
    final rec = Rec();
    final c = ProviderContainer(overrides: [
      analyticsProvider.overrideWithValue(rec),
      accountProvider.overrideWith((ref) => Stream.value(const Account(kind: AccountKind.guest, uid: 'u1'))),
    ]);
    c.listen(telemetryProvider, (_, _) {});
    await Future<void>.delayed(const Duration(milliseconds: 50));
    expect(rec.props, containsAll(['id=u1', 'account_kind=guest', 'plan=free']));
    c.dispose();
  });
}
