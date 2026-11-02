// Plants deliberate layering violations in a temporary lib/ and checks that
// each one is caught, and that the allowed imports pass.

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import '../../tool/layering/layer_rules.dart';

const _pkg = 'gridwell_flutter_app';

/// Writes [files] (path relative to lib/ -> contents) into a temp lib/ and checks it.
List<LayerViolation> _run(Map<String, String> files) {
  final tmp = Directory.systemTemp.createTempSync('layers_');
  addTearDown(() => tmp.deleteSync(recursive: true));
  final lib = Directory('${tmp.path}/lib')..createSync();
  files.forEach((path, contents) {
    File('${lib.path}/$path')
      ..createSync(recursive: true)
      ..writeAsStringSync(contents);
  });
  return checkLayers(lib, _pkg);
}

void main() {
  group('planted violations are caught', () {
    final cases = <String, Map<String, String>>{
      'engine imports Flutter': {
        'engine/solver/x.dart': "import 'package:flutter/foundation.dart';",
      },
      'engine imports Riverpod': {
        'engine/solver/x.dart': "import 'package:flutter_riverpod/flutter_riverpod.dart';",
      },
      'engine imports dart:io': {
        'engine/solver/x.dart': "import 'dart:io';",
      },
      'engine imports dart:async': {
        'engine/model/x.dart': "import 'dart:async';",
      },
      'engine imports state via package uri': {
        'engine/solver/x.dart': "import 'package:$_pkg/state/board_notifier.dart';",
      },
      'engine imports ui via relative path': {
        'engine/solver/x.dart': "import '../../ui/board.dart';",
      },
      'ui imports the solver': {
        'ui/board/board_view.dart': "import 'package:$_pkg/engine/solver/line_solver.dart';",
      },
      'ui imports difficulty via relative path': {
        'ui/board/board_view.dart': "import '../../engine/difficulty/difficulty.dart';",
      },
      'ui imports data directly': {
        'ui/screens/a.dart': "import 'package:$_pkg/data/db.dart';",
      },
      'ui imports services directly': {
        'ui/screens/a.dart': "import 'package:$_pkg/services/ads/ad_service.dart';",
      },
      'state imports ui': {
        'state/a.dart': "import 'package:$_pkg/ui/theme.dart';",
      },
      'content imports a package': {
        'content/a.dart': "import 'package:flutter/services.dart';",
      },
      'data imports state': {
        'data/a.dart': "import '../state/a.dart';",
      },
      'services imports ui': {
        'services/a.dart': "export 'package:$_pkg/ui/a.dart';",
      },
      'riverpod codegen anywhere': {
        'state/a.dart': "import 'package:riverpod_annotation/riverpod_annotation.dart';",
      },
    };

    cases.forEach((name, files) {
      test(name, () {
        final violations = _run(files);
        expect(violations, hasLength(1), reason: violations.join('\n'));
      });
    });
  });

  test('allowed imports pass', () {
    final violations = _run({
      'engine/solver/line_solver.dart':
          "import 'dart:math';\nimport '../model/puzzle.dart';\nimport 'package:$_pkg/engine/model/board.dart';",
      'content/decoder.dart':
          "import 'dart:typed_data';\nimport 'dart:io';\nimport '../engine/model/puzzle.dart';",
      'state/board_notifier.dart':
          "import 'package:flutter_riverpod/flutter_riverpod.dart';\nimport '../engine/solver/line_solver.dart';\nimport '../data/db.dart';",
      'ui/board/board_view.dart':
          "import 'package:flutter/widgets.dart';\nimport 'package:$_pkg/engine/model/cell_state.dart';\nimport '../../state/board_notifier.dart';",
      'main.dart': "import 'package:$_pkg/data/db.dart';\nimport 'ui/app.dart';",
    });
    expect(violations, isEmpty, reason: violations.join('\n'));
  });

  test('the real lib/ passes', () {
    final violations = checkLayers(Directory('lib'), _pkg);
    expect(violations, isEmpty, reason: violations.join('\n'));
  });
}
