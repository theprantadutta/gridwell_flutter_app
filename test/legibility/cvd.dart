// Color-vision simulation and contrast math for the legibility harness.

import 'dart:math' as math;
import 'dart:ui';

enum Vision { typical, protanopia, deuteranopia, tritanopia, monochromacy }

/// Machado, Oliveira & Fernandes (2009), severity 1.0, applied in linear RGB.
const _machado = {
  Vision.protanopia: [
    [0.152286, 1.052583, -0.204868],
    [0.114503, 0.786281, 0.099216],
    [-0.003882, -0.048116, 1.051998],
  ],
  Vision.deuteranopia: [
    [0.367322, 0.860646, -0.227968],
    [0.280085, 0.672501, 0.047413],
    [-0.011820, 0.042940, 0.968881],
  ],
  Vision.tritanopia: [
    [1.255528, -0.076749, -0.178779],
    [-0.078411, 0.930809, 0.147602],
    [0.004733, 0.691367, 0.303900],
  ],
};

double _toLinear(double c) =>
    c <= 0.04045 ? c / 12.92 : math.pow((c + 0.055) / 1.055, 2.4).toDouble();

double _toSrgb(double c) {
  final v = c.clamp(0.0, 1.0);
  return v <= 0.0031308 ? 12.92 * v : 1.055 * math.pow(v, 1 / 2.4) - 0.055;
}

/// [color] as seen with [vision]. Alpha is ignored (composite first).
Color simulate(Color color, Vision vision) {
  final lin = [_toLinear(color.r), _toLinear(color.g), _toLinear(color.b)];
  List<double> out;
  switch (vision) {
    case Vision.typical:
      return color;
    case Vision.monochromacy:
      final y = 0.2126 * lin[0] + 0.7152 * lin[1] + 0.0722 * lin[2];
      out = [y, y, y];
    default:
      final m = _machado[vision]!;
      out = [
        for (final row in m) row[0] * lin[0] + row[1] * lin[1] + row[2] * lin[2],
      ];
  }
  return Color.from(
    alpha: 1,
    red: _toSrgb(out[0]),
    green: _toSrgb(out[1]),
    blue: _toSrgb(out[2]),
  );
}

/// WCAG relative luminance.
double luminance(Color c) =>
    0.2126 * _toLinear(c.r) + 0.7152 * _toLinear(c.g) + 0.0722 * _toLinear(c.b);

/// WCAG contrast ratio, 1..21.
double contrast(Color a, Color b) {
  final la = luminance(a), lb = luminance(b);
  final hi = math.max(la, lb), lo = math.min(la, lb);
  return (hi + 0.05) / (lo + 0.05);
}

/// [top] composited over opaque [bottom] with [mode] (multiply or srcOver).
Color composite(Color top, Color bottom, BlendMode mode) {
  double ch(double t, double b) => switch (mode) {
        BlendMode.multiply => t * b,
        _ => t * top.a + b * (1 - top.a),
      };
  if (mode == BlendMode.multiply) {
    // Multiply with the top color's own alpha.
    double m(double t, double b) => (t * b) * top.a + b * (1 - top.a);
    return Color.from(
        alpha: 1, red: m(top.r, bottom.r), green: m(top.g, bottom.g), blue: m(top.b, bottom.b));
  }
  return Color.from(
      alpha: 1, red: ch(top.r, bottom.r), green: ch(top.g, bottom.g), blue: ch(top.b, bottom.b));
}
