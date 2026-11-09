import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/services.dart';

/// Loads the bundled Schibsted Grotesk weights so widget tests lay text out
/// with the real font instead of the test font.
Future<void> loadTallyFonts() async {
  Future<ByteData> read(String w) async =>
      ByteData.sublistView(File('assets/fonts/SchibstedGrotesk-$w.ttf').readAsBytesSync());
  final loader = FontLoader('Schibsted Grotesk');
  for (final w in ['Medium', 'Bold', 'ExtraBold', 'Black']) {
    loader.addFont(read(w));
  }
  await loader.load();
}
