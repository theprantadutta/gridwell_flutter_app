import 'package:integration_test/integration_test_driver.dart';

/// Writes the integration test's performance report to build/board_perf.json.
Future<void> main() => integrationDriver(
      responseDataCallback: (data) async {
        if (data != null) await writeResponseData(data, testOutputFilename: 'board_perf');
      },
    );
