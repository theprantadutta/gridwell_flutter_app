// Layering rules for lib/. See CLAUDE.md, "Architecture and layering".
//
// Pure Dart (dart:io only) so it runs as a CLI and inside tests without Flutter.

import 'dart:io';

/// A single import that breaks a layering rule.
class LayerViolation {
  LayerViolation(this.file, this.line, this.directive, this.reason);

  final String file;
  final int line;
  final String directive;
  final String reason;

  @override
  String toString() => '$file:$line  $directive\n    -> $reason';
}

/// Top-level folders under lib/ that form layers.
enum Layer { engine, content, data, services, state, ui, root }

/// Resolved target of an import or export.
class _Target {
  _Target.dart(this.dartLibrary)
      : package = null,
        libPath = null;
  _Target.local(this.libPath)
      : package = null,
        dartLibrary = null;
  _Target.package(this.package)
      : libPath = null,
        dartLibrary = null;

  /// e.g. `math` for `dart:math`.
  final String? dartLibrary;

  /// Path relative to lib/ (forward slashes) for imports inside this package.
  final String? libPath;

  /// Package name for third-party imports.
  final String? package;
}

final _directive = RegExp(r'''^\s*(import|export)\s+['"]([^'"]+)['"]''');

/// Packages that must never appear anywhere (Riverpod is manual providers only).
const _bannedPackages = {'riverpod_annotation', 'riverpod_generator'};

/// Checks every .dart file under [libRoot] and returns all violations.
///
/// [packageName] is this app's package name, used to resolve `package:` imports
/// that point back into lib/.
List<LayerViolation> checkLayers(Directory libRoot, String packageName) {
  final violations = <LayerViolation>[];
  final rootPath = _norm(libRoot.absolute.path);

  final files = libRoot
      .listSync(recursive: true)
      .whereType<File>()
      .where((f) => f.path.endsWith('.dart'))
      .toList()
    ..sort((a, b) => a.path.compareTo(b.path));

  for (final file in files) {
    final filePath = _norm(file.absolute.path);
    final relPath = filePath.substring(rootPath.length + 1);
    final layer = layerOf(relPath);
    final lines = file.readAsLinesSync();

    for (var i = 0; i < lines.length; i++) {
      final match = _directive.firstMatch(lines[i]);
      if (match == null) continue;
      final uri = match.group(2)!;
      final target = _resolve(uri, relPath, packageName);
      final reason = _check(layer, relPath, target);
      if (reason != null) {
        violations.add(LayerViolation(relPath, i + 1, lines[i].trim(), reason));
      }
    }
  }
  return violations;
}

/// Layer of a file given its path relative to lib/.
Layer layerOf(String relPath) {
  final first = relPath.split('/').first;
  for (final layer in Layer.values) {
    if (layer != Layer.root && layer.name == first) return layer;
  }
  return Layer.root;
}

String _norm(String p) => p.replaceAll('\\', '/');

_Target _resolve(String uri, String fromRelPath, String packageName) {
  if (uri.startsWith('dart:')) return _Target.dart(uri.substring(5));
  if (uri.startsWith('package:')) {
    final rest = uri.substring(8);
    final slash = rest.indexOf('/');
    final pkg = slash < 0 ? rest : rest.substring(0, slash);
    if (pkg == packageName && slash >= 0) {
      return _Target.local(rest.substring(slash + 1));
    }
    return _Target.package(pkg);
  }
  // Relative import: resolve against the importing file's directory.
  final parts = fromRelPath.split('/')..removeLast();
  for (final segment in uri.split('/')) {
    if (segment == '..') {
      if (parts.isNotEmpty) parts.removeLast();
    } else if (segment != '.') {
      parts.add(segment);
    }
  }
  return _Target.local(parts.join('/'));
}

/// Returns a reason string if the import is not allowed, otherwise null.
String? _check(Layer from, String fromPath, _Target target) {
  if (target.package != null && _bannedPackages.contains(target.package)) {
    return 'package:${target.package} is banned: Riverpod uses hand-written providers only';
  }

  final targetLayer = target.libPath == null ? null : layerOf(target.libPath!);
  final isEngineModel = target.libPath?.startsWith('engine/model/') ?? false;

  switch (from) {
    case Layer.engine:
      if (target.dartLibrary != null) {
        return const {'core', 'math'}.contains(target.dartLibrary)
            ? null
            : 'engine/ may import only dart:core and dart:math (found dart:${target.dartLibrary})';
      }
      if (target.package != null) {
        return 'engine/ must not import packages (found package:${target.package})';
      }
      return targetLayer == Layer.engine
          ? null
          : 'engine/ must not import ${targetLayer!.name}/';

    case Layer.content:
      if (target.dartLibrary != null) {
        return const {'core', 'math', 'typed_data', 'io', 'convert'}
                .contains(target.dartLibrary)
            ? null
            : 'content/ may import only dart:core, math, typed_data, io, convert (found dart:${target.dartLibrary})';
      }
      if (target.package != null) {
        return 'content/ must not import packages (found package:${target.package})';
      }
      return const {Layer.engine, Layer.content}.contains(targetLayer)
          ? null
          : 'content/ may import only engine/ and content/ (found ${targetLayer!.name}/)';

    case Layer.data:
      return const {Layer.state, Layer.ui, Layer.services}.contains(targetLayer)
          ? 'data/ must not import ${targetLayer!.name}/'
          : null;

    case Layer.services:
      return const {Layer.state, Layer.ui, Layer.data}.contains(targetLayer)
          ? 'services/ must not import ${targetLayer!.name}/'
          : null;

    case Layer.state:
      return targetLayer == Layer.ui ? 'state/ must not import ui/' : null;

    case Layer.ui:
      if (targetLayer == Layer.engine && !isEngineModel) {
        return 'ui/ may import only engine value types (engine/model/), not engine logic (${target.libPath})';
      }
      if (const {Layer.data, Layer.services, Layer.content}.contains(targetLayer)) {
        return 'ui/ must go through state/, not import ${targetLayer!.name}/ directly';
      }
      return null;

    case Layer.root:
      // main.dart and app bootstrap files are the composition root.
      return null;
  }
}
