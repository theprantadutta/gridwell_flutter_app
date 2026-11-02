import 'dart:convert';
import 'dart:typed_data';

import '../engine/model/clues.dart';
import '../engine/model/puzzle.dart';
import '../engine/model/solution.dart';

/// Picture palette indices stored per cell. 0 is background (empty in the
/// solution). The UI maps these to the Folio art tokens.
abstract final class PictureColor {
  static const background = 0;
  static const ink = 1; // art-b
  static const red = 2; // art-a
  static const ochre = 3; // art-c
  static const stone = 4; // art-d
  static const indigo = 5; // art-e
}

/// A themed set of plates.
class CollectionInfo {
  const CollectionInfo({
    required this.id,
    required this.name,
    required this.blurb,
  });

  final String id;
  final String name;

  /// One line for the collection page, e.g. "Harbor and shore."
  final String blurb;
}

/// Everything baked into `assets/puzzles/set.bin`.
class PuzzleSet {
  PuzzleSet({
    required this.puzzleSetVersion,
    required this.seed,
    required List<CollectionInfo> collections,
    required List<PuzzleRecord> puzzles,
    this.dailyStartDate = '',
    List<PuzzleRecord> dailyPool = const [],
  })  : collections = List.unmodifiable(collections),
        puzzles = List.unmodifiable(puzzles),
        dailyPool = List.unmodifiable(dailyPool);

  /// First day of the daily calendar (yyyy-MM-dd), shared with the server.
  final String dailyStartDate;

  /// Daily puzzles in serving order: day N after [dailyStartDate] is
  /// `dailyPool[N % length]`. Bundled so the daily works with no connection.
  final List<PuzzleRecord> dailyPool;

  /// Bumped whenever any shipped puzzle changes. Progress stores it.
  final int puzzleSetVersion;

  /// Seed the set was baked with (informational).
  final int seed;
  final List<CollectionInfo> collections;

  /// Ordered by collection, then plate number.
  final List<PuzzleRecord> puzzles;

  List<PuzzleRecord> inCollection(String collectionId) =>
      puzzles.where((p) => p.collectionId == collectionId).toList();
}

/// Binary codec for [PuzzleSet].
///
/// Layout, little-endian:
/// ```
/// magic 'GWPS' | u16 format | u32 puzzleSetVersion | u32 seed
/// u16 collectionCount, then per collection: str id, str name, str blurb
/// u16 puzzleCount, then per puzzle:
///   str id, str name, u8 collectionIndex, u16 plateNumber,
///   u8 width, u8 height, u16 difficulty x 100,
///   ceil(width*height*3/8) bytes: 3-bit color index per cell, row-major, LSB first
/// str dailyStartDate, u16 dailyCount, then per daily:
///   str id, str name, u8 width, u8 height, u16 difficulty x 100, color bytes
/// str = u16 byte length + UTF-8 bytes
/// ```
/// Stored uncompressed so the bytes never depend on a zlib version; the app
/// bundle compresses it anyway. Clues are derived on load.
abstract final class PuzzleSetCodec {
  static const _magic = [0x47, 0x57, 0x50, 0x53]; // GWPS
  static const formatVersion = 2;

  static Uint8List encode(PuzzleSet set) {
    final out = _Writer();
    for (final b in _magic) {
      out.u8(b);
    }
    out
      ..u16(formatVersion)
      ..u32(set.puzzleSetVersion)
      ..u32(set.seed)
      ..u16(set.collections.length);
    final collectionIndex = <String, int>{};
    for (var i = 0; i < set.collections.length; i++) {
      final c = set.collections[i];
      collectionIndex[c.id] = i;
      out
        ..str(c.id)
        ..str(c.name)
        ..str(c.blurb);
    }
    out.u16(set.puzzles.length);
    for (final p in set.puzzles) {
      final index = collectionIndex[p.collectionId];
      if (index == null) {
        throw ArgumentError('Puzzle ${p.id} names unknown collection ${p.collectionId}');
      }
      if (p.width > 255 || p.height > 255) {
        throw ArgumentError('Puzzle ${p.id} is too large');
      }
      final colors = p.colorLayer ??
          [for (final filled in p.solution.cells) filled ? PictureColor.ink : 0];
      out
        ..str(p.id)
        ..str(p.name)
        ..u8(index)
        ..u16(p.plateNumber)
        ..u8(p.width)
        ..u8(p.height)
        ..u16((p.difficulty * 100).round())
        ..bytes(_pack(colors));
    }
    out
      ..str(set.dailyStartDate)
      ..u16(set.dailyPool.length);
    for (final p in set.dailyPool) {
      out
        ..str(p.id)
        ..str(p.name)
        ..u8(p.width)
        ..u8(p.height)
        ..u16((p.difficulty * 100).round())
        ..bytes(_pack(p.colorLayer ?? [for (final f in p.solution.cells) f ? PictureColor.ink : 0]));
    }
    return out.take();
  }

  static PuzzleRecord _record(String id, String name, String collection, int plate, int w, int h,
      double difficulty, List<int> colors) {
    final solution = Solution(w, h, [for (final c in colors) c != 0]);
    return PuzzleRecord(
      id: id,
      name: name,
      solution: solution,
      clues: Clues.fromSolution(solution),
      difficulty: difficulty,
      collectionId: collection,
      plateNumber: plate,
      colorLayer: colors,
    );
  }

  static PuzzleSet decode(Uint8List data) {
    final r = _Reader(data);
    for (final b in _magic) {
      if (r.u8() != b) throw const FormatException('Not a Gridwell puzzle set');
    }
    final format = r.u16();
    if (format != formatVersion) {
      throw FormatException('Unsupported puzzle set format $format');
    }
    final setVersion = r.u32();
    final seed = r.u32();
    final collections = <CollectionInfo>[
      for (var i = r.u16(); i > 0; i--)
        CollectionInfo(id: r.str(), name: r.str(), blurb: r.str()),
    ];
    final puzzles = <PuzzleRecord>[];
    for (var i = r.u16(); i > 0; i--) {
      final id = r.str();
      final name = r.str();
      final collection = collections[r.u8()].id;
      final plate = r.u16();
      final w = r.u8();
      final h = r.u8();
      final difficulty = r.u16() / 100;
      final colors = _unpack(r.bytes((w * h * 3 + 7) ~/ 8), w * h);
      puzzles.add(_record(id, name, collection, plate, w, h, difficulty, colors));
    }
    final dailyStart = r.str();
    final daily = <PuzzleRecord>[];
    for (var i = r.u16(); i > 0; i--) {
      final id = r.str();
      final name = r.str();
      final w = r.u8();
      final h = r.u8();
      final difficulty = r.u16() / 100;
      final colors = _unpack(r.bytes((w * h * 3 + 7) ~/ 8), w * h);
      daily.add(_record(id, name, 'daily', 0, w, h, difficulty, colors));
    }
    if (!r.atEnd) throw const FormatException('Trailing bytes in puzzle set');
    return PuzzleSet(
      puzzleSetVersion: setVersion,
      seed: seed,
      collections: collections,
      puzzles: puzzles,
      dailyStartDate: dailyStart,
      dailyPool: daily,
    );
  }

  static Uint8List _pack(List<int> colors) {
    final out = Uint8List((colors.length * 3 + 7) ~/ 8);
    for (var i = 0; i < colors.length; i++) {
      final c = colors[i];
      if (c < 0 || c > 7) throw ArgumentError('Color index $c out of range');
      for (var b = 0; b < 3; b++) {
        if ((c >> b) & 1 == 1) {
          final bit = i * 3 + b;
          out[bit >> 3] |= 1 << (bit & 7);
        }
      }
    }
    return out;
  }

  static List<int> _unpack(Uint8List bytes, int count) => List<int>.generate(count, (i) {
        var c = 0;
        for (var b = 0; b < 3; b++) {
          final bit = i * 3 + b;
          if ((bytes[bit >> 3] >> (bit & 7)) & 1 == 1) c |= 1 << b;
        }
        return c;
      });
}

class _Writer {
  final _builder = BytesBuilder(copy: false);
  final _scratch = ByteData(4);

  void u8(int v) => _builder.addByte(v);

  void u16(int v) {
    _scratch.setUint16(0, v, Endian.little);
    _builder.add(_scratch.buffer.asUint8List(0, 2).toList());
  }

  void u32(int v) {
    _scratch.setUint32(0, v, Endian.little);
    _builder.add(_scratch.buffer.asUint8List(0, 4).toList());
  }

  void str(String s) {
    final b = utf8.encode(s);
    u16(b.length);
    _builder.add(b);
  }

  void bytes(Uint8List b) => _builder.add(b);

  Uint8List take() => _builder.takeBytes();
}

class _Reader {
  _Reader(this._data) : _view = ByteData.sublistView(_data);

  final Uint8List _data;
  final ByteData _view;
  var _pos = 0;

  bool get atEnd => _pos == _data.length;

  void _need(int n) {
    if (_pos + n > _data.length) throw const FormatException('Truncated puzzle set');
  }

  int u8() {
    _need(1);
    return _data[_pos++];
  }

  int u16() {
    _need(2);
    final v = _view.getUint16(_pos, Endian.little);
    _pos += 2;
    return v;
  }

  int u32() {
    _need(4);
    final v = _view.getUint32(_pos, Endian.little);
    _pos += 4;
    return v;
  }

  String str() => utf8.decode(bytes(u16()));

  Uint8List bytes(int n) {
    _need(n);
    final b = Uint8List.sublistView(_data, _pos, _pos + n);
    _pos += n;
    return b;
  }
}
