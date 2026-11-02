// Enforces the lib/ layering rules. Exits 1 if any import breaks them.
//
//   dart run tool/check_layers.dart [libDir]

import 'dart:io';

import 'layering/layer_rules.dart';

void main(List<String> args) {
  final libDir = Directory(args.isNotEmpty ? args.first : 'lib');
  if (!libDir.existsSync()) {
    stderr.writeln('Directory not found: ${libDir.path}');
    exit(2);
  }
  final violations = checkLayers(libDir, 'gridwell_flutter_app');
  if (violations.isEmpty) {
    stdout.writeln('Layering OK (${libDir.path})');
    return;
  }
  stderr.writeln('${violations.length} layering violation(s):');
  for (final v in violations) {
    stderr.writeln(v);
  }
  exit(1);
}
