// The Flutter splash hands over from the native splash image (the logo kit's
// render). For the hand-off to be invisible, the painted mark must match the
// kit pixel for pixel, within anti-aliasing.

import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter_test/flutter_test.dart';
import 'package:gridwell_flutter_app/ui/theme/palette.dart';
import 'package:gridwell_flutter_app/ui/widgets/gridwell_mark.dart';

Future<List<int>> _rgba(ui.Image image) async =>
    (await image.toByteData(format: ui.ImageByteFormat.rawRgba))!.buffer.asUint8List();

void main() {
  for (final (name, palette) in [('light', GridwellPalette.light), ('dark', GridwellPalette.dark)]) {
    test('painted mark matches the kit render ($name)', () async {
      const size = 1024;
      final recorder = ui.PictureRecorder();
      GridwellMarkPainter(palette).paint(ui.Canvas(recorder), const ui.Size(1024, 1024));
      final painted = await _rgba(await recorder.endRecording().toImage(size, size));

      final codec = await ui.instantiateImageCodec(
          File('brand/01-mark/png/gridwell-mark-$name-1024.png').readAsBytesSync());
      final kit = await _rgba((await codec.getNextFrame()).image);

      var mismatched = 0;
      for (var i = 0; i < size * size; i++) {
        final o = i * 4;
        final d = (painted[o] - kit[o]).abs() + (painted[o + 1] - kit[o + 1]).abs() + (painted[o + 2] - kit[o + 2]).abs();
        if (d > 24) mismatched++;
      }
      final ratio = mismatched / (size * size);
      // Anti-aliased edges differ slightly; anything structural would be far above 2%.
      expect(ratio, lessThan(0.02), reason: '$name: ${(ratio * 100).toStringAsFixed(2)}% of pixels differ');
    });
  }
}
