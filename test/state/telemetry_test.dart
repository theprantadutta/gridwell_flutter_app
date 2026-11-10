import 'package:flutter_test/flutter_test.dart';
import 'package:gridwell_flutter_app/state/telemetry.dart';

void main() {
  test('route patterns map to stable screen names', () {
    expect(Telemetry.screenName('/contents'), 'contents');
    expect(Telemetry.screenName('/play/:id'), 'board');
    expect(Telemetry.screenName('/collection/:id'), 'collection');
    expect(Telemetry.screenName('/account/email'), 'account_email');
    expect(Telemetry.screenName('/legal/:doc'), 'legal');
    expect(Telemetry.screenName('/'), 'home');
  });
}
