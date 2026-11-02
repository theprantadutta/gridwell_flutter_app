import 'dart:math' as math;

import 'package:flutter/widgets.dart';

import '../../engine/model/board.dart';
import '../../engine/model/clues.dart';
import '../theme/gridwell_theme.dart';
import 'board_geometry.dart';
import 'board_painter.dart';

/// The puzzle board: clues and grid, painted, with drag-to-paint input and a
/// two-finger pinch to zoom when cells are small.
class BoardView extends StatefulWidget {
  const BoardView({
    super.key,
    required this.clues,
    required this.board,
    required this.rowRetired,
    required this.colRetired,
    required this.mistakes,
    required this.onStrokeStart,
    required this.onStrokeMove,
    required this.onStrokeEnd,
    required this.onStrokeCancel,
    this.cursorRow,
    this.cursorCol,
    this.flashCell,
    this.enabled = true,
  });

  final Clues clues;
  final Board board;
  final List<Set<int>> rowRetired;
  final List<Set<int>> colRetired;
  final Set<int> mistakes;
  final int? cursorRow;
  final int? cursorCol;

  /// (row, col) to ring, e.g. the hinted cell.
  final (int, int)? flashCell;
  final bool enabled;
  final void Function(int row, int col) onStrokeStart;
  final void Function(int row, int col) onStrokeMove;
  final VoidCallback onStrokeEnd;
  final VoidCallback onStrokeCancel;

  /// Cells smaller than this unlock pinch-zoom.
  static const zoomThreshold = 18.0;

  @override
  State<BoardView> createState() => _BoardViewState();
}

class _BoardViewState extends State<BoardView> {
  final _pointers = <int, Offset>{};
  bool _stroking = false;
  bool _scaling = false;

  // Zoom state.
  double _scale = 1;
  Offset _offset = Offset.zero;
  double _startScale = 1;
  double _startDistance = 1;
  Offset _startFocal = Offset.zero;
  Offset _startOffset = Offset.zero;

  BoardGeometry? _geometry;
  Size _viewport = Size.zero;

  double get _maxScale {
    final g = _geometry;
    if (g == null || g.cell >= BoardView.zoomThreshold) return 1;
    return math.max(1, 30 / g.cell);
  }

  Offset _toBoard(Offset local) => (local - _offset) / _scale;

  void _clampOffset() {
    final g = _geometry;
    if (g == null) return;
    final content = g.totalSize * _scale;
    double clampAxis(double v, double contentExtent, double viewExtent) {
      if (contentExtent <= viewExtent) return (viewExtent - contentExtent) / 2;
      return v.clamp(viewExtent - contentExtent, 0);
    }

    _offset = Offset(
      clampAxis(_offset.dx, content.width, _viewport.width),
      clampAxis(_offset.dy, content.height, _viewport.height),
    );
  }

  void _down(PointerDownEvent e) {
    _pointers[e.pointer] = e.localPosition;
    if (_pointers.length == 1 && widget.enabled) {
      final hit = _geometry?.cellAt(_toBoard(e.localPosition));
      if (hit != null) {
        _stroking = true;
        widget.onStrokeStart(hit.$1, hit.$2);
      }
    } else if (_pointers.length == 2) {
      if (_stroking) {
        _stroking = false;
        widget.onStrokeCancel();
      }
      if (_maxScale > 1) {
        _scaling = true;
        final pts = _pointers.values.toList();
        _startDistance = math.max(1, (pts[0] - pts[1]).distance);
        _startFocal = (pts[0] + pts[1]) / 2;
        _startScale = _scale;
        _startOffset = _offset;
      }
    }
  }

  void _move(PointerMoveEvent e) {
    if (!_pointers.containsKey(e.pointer)) return;
    _pointers[e.pointer] = e.localPosition;
    if (_scaling && _pointers.length >= 2) {
      final pts = _pointers.values.take(2).toList();
      final distance = math.max(1.0, (pts[0] - pts[1]).distance);
      final focal = (pts[0] + pts[1]) / 2;
      final scale = (_startScale * distance / _startDistance).clamp(1.0, _maxScale);
      // Keep the board point under the starting focal point under the fingers.
      final anchor = (_startFocal - _startOffset) / _startScale;
      setState(() {
        _scale = scale;
        _offset = focal - anchor * scale;
        _clampOffset();
      });
    } else if (_stroking) {
      final hit = _geometry?.cellAt(_toBoard(e.localPosition), clamp: true);
      if (hit != null) widget.onStrokeMove(hit.$1, hit.$2);
    }
  }

  void _up(PointerEvent e) {
    _pointers.remove(e.pointer);
    if (_stroking && _pointers.isEmpty) {
      _stroking = false;
      widget.onStrokeEnd();
    }
    if (_pointers.isEmpty) _scaling = false;
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return LayoutBuilder(builder: (context, constraints) {
      final available = Size(constraints.maxWidth, constraints.maxHeight);
      final g = BoardGeometry.fit(widget.clues, available);
      if (_geometry?.cell != g.cell || _viewport != available) {
        _geometry = g;
        _viewport = available;
        if (_maxScale <= 1) _scale = 1;
        _clampOffset();
      }
      final flash = widget.flashCell;
      return Listener(
        behavior: HitTestBehavior.opaque,
        onPointerDown: _down,
        onPointerMove: _move,
        onPointerUp: _up,
        onPointerCancel: _up,
        child: ClipRect(
          child: Stack(children: [
            Positioned(
              left: _offset.dx,
              top: _offset.dy,
              child: Transform.scale(
                scale: _scale,
                alignment: Alignment.topLeft,
                child: SizedBox.fromSize(
                  size: g.totalSize,
                  child: Stack(children: [
                    RepaintBoundary(
                      child: CustomPaint(
                        size: g.totalSize,
                        painter: GridPainter(
                          geometry: g,
                          board: widget.board,
                          palette: palette,
                          mistakes: widget.mistakes,
                          cursorRow: widget.cursorRow,
                          cursorCol: widget.cursorCol,
                          flashRect: flash == null ? null : g.cellRect(flash.$1, flash.$2),
                        ),
                      ),
                    ),
                    RepaintBoundary(
                      child: CustomPaint(
                        size: g.totalSize,
                        painter: CluePainter(
                          geometry: g,
                          clues: widget.clues,
                          palette: palette,
                          rowRetired: widget.rowRetired,
                          colRetired: widget.colRetired,
                          activeRow: widget.cursorRow,
                          activeCol: widget.cursorCol,
                        ),
                      ),
                    ),
                  ]),
                ),
              ),
            ),
          ]),
        ),
      );
    });
  }
}
