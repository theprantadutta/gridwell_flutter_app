import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme/gridwell_theme.dart';
import '../theme/typography.dart';
import 'gridwell_mark.dart';

/// Horizontal page margin used across Folio screens.
const folioMargin = 24.0;

/// Page body for pushed screens: a [SafeArea] whose content is centered and
/// held to a comfortable reading width, so tablets get a page rather than
/// lines stretched edge to edge. Phones are narrower than [maxWidth] and are
/// unaffected.
class FolioBody extends StatelessWidget {
  const FolioBody({super.key, required this.child, this.maxWidth = 640});

  final Widget child;
  final double maxWidth;

  @override
  Widget build(BuildContext context) => SafeArea(
        child: Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(constraints: BoxConstraints(maxWidth: maxWidth), child: child),
        ),
      );
}

class Hairline extends StatelessWidget {
  const Hairline({super.key, this.strong = false, this.thickness = 1});

  final bool strong;
  final double thickness;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Container(height: thickness, color: strong ? p.textPrimary : p.rule);
  }
}

/// The running head: "‹ Contents     Coastline     6:18", over a hairline.
class FolioHeader extends StatelessWidget {
  const FolioHeader({super.key, this.leading, this.center, this.trailing, this.onLeading});

  final String? leading;
  final String? center;
  final Widget? trailing;
  final VoidCallback? onLeading;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final style = FolioType.header(p);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: folioMargin),
      child: Column(children: [
        ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 52),
          child: Row(children: [
            Expanded(
              flex: 2,
              child: Align(
                alignment: Alignment.centerLeft,
                child: leading == null
                    ? const SizedBox()
                    : Semantics(
                        button: true,
                        label: 'Back to ${leading!}',
                        child: GestureDetector(
                          behavior: HitTestBehavior.opaque,
                          onTap: onLeading ?? () => Navigator.of(context).maybePop(),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            child: Text('‹ ${leading!}', maxLines: 1, overflow: TextOverflow.ellipsis, style: style),
                          ),
                        ),
                      ),
              ),
            ),
            const SizedBox(width: 8),
            // Equal side columns keep the title centered on the page.
            Expanded(
              flex: 3,
              child: center == null
                  ? const SizedBox()
                  : Text(center!,
                      maxLines: 1, overflow: TextOverflow.ellipsis, textAlign: TextAlign.center, style: style),
            ),
            const SizedBox(width: 8),
            Expanded(
              flex: 2,
              child: Align(
                alignment: Alignment.centerRight,
                child: FittedBox(fit: BoxFit.scaleDown, alignment: Alignment.centerRight, child: trailing ?? const SizedBox()),
              ),
            ),
          ]),
        ),
        const Hairline(),
      ]),
    );
  }
}

/// Header for tab pages: "GRIDWELL ..... 86 of 240 solved".
class WordmarkHeader extends StatelessWidget {
  const WordmarkHeader({super.key, this.trailing});

  final String? trailing;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: folioMargin),
      child: Column(children: [
        ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 52),
          child: Row(children: [
            const GridwellMark(size: 20), // the logo kit's minimum mark size
            const SizedBox(width: 10),
            Text('GRIDWELL', style: FolioType.wordmark(p)),
            const SizedBox(width: 16),
            if (trailing != null)
              Expanded(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerRight,
                  child: Text(trailing!, maxLines: 1, style: FolioType.header(p)),
                ),
              ),
          ]),
        ),
        const Hairline(),
      ]),
    );
  }
}

/// Primary action: an ink slab with a label left and detail right.
class InkButton extends StatelessWidget {
  const InkButton({super.key, required this.label, this.detail, required this.onPressed, this.height = 64});

  final String label;
  final String? detail;
  final VoidCallback? onPressed;
  final double height;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Semantics(
      button: true,
      label: detail == null ? label : '$label, $detail',
      child: GestureDetector(
        onTap: onPressed,
        child: Container(
          height: height,
          padding: const EdgeInsets.symmetric(horizontal: 22),
          decoration: BoxDecoration(color: p.textPrimary, borderRadius: BorderRadius.circular(4)),
          child: LayoutBuilder(builder: (context, c) {
            final labelStyle = FolioType.button(p.onInk, size: 19);
            final detailStyle = FolioType.style(size: 16, color: p.onInk.withValues(alpha: 0.75));
            final scaler = MediaQuery.textScalerOf(context);
            double natural(String t, TextStyle st) =>
                (TextPainter(text: TextSpan(text: t, style: st), textDirection: TextDirection.ltr, textScaler: scaler, maxLines: 1)
                      ..layout())
                    .width +
                1;
            final labelW = natural(label, labelStyle);
            final detailW = detail == null ? 0.0 : natural(detail!, detailStyle) + 12;
            // Both at natural size when they fit. Otherwise the detail gives
            // way first (ellipsis), and the label shrinks only if it alone is
            // too wide.
            final labelMax = detail == null || labelW + detailW <= c.maxWidth
                ? c.maxWidth
                : math.max(labelW.clamp(0.0, c.maxWidth * 0.65), c.maxWidth - detailW);
            return Row(children: [
              ConstrainedBox(
                constraints: BoxConstraints(maxWidth: math.min(labelMax, c.maxWidth)),
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(label, maxLines: 1, style: labelStyle),
                ),
              ),
              if (detail != null) ...[
                const SizedBox(width: 12),
                Expanded(
                  child: Text(detail!,
                      maxLines: 1, overflow: TextOverflow.ellipsis, textAlign: TextAlign.right, style: detailStyle),
                ),
              ],
            ]);
          }),
        ),
      ),
    );
  }
}

/// Secondary action: outlined, same footprint as [InkButton].
class OutlineButtonFolio extends StatelessWidget {
  const OutlineButtonFolio({super.key, required this.label, required this.onPressed, this.height = 54});

  final String label;
  final VoidCallback? onPressed;
  final double height;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Semantics(
      button: true,
      label: label,
      child: GestureDetector(
        onTap: onPressed,
        child: Container(
          height: height,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            border: Border.all(color: p.textPrimary, width: 1.2),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Text(label, style: FolioType.button(p.textPrimary, size: 18).copyWith(fontWeight: FontWeight.w400)),
        ),
      ),
    );
  }
}

/// A quiet italic text action: "Undo", "Solve again".
class TextAction extends StatelessWidget {
  const TextAction({super.key, required this.label, required this.onPressed, this.trailing, this.enabled = true});

  final String label;
  final Widget? trailing;
  final VoidCallback? onPressed;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Semantics(
      button: true,
      enabled: enabled,
      label: label,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: enabled ? onPressed : null,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 4),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            Text(label,
                style: FolioType.style(
                    size: 20, color: enabled ? p.textPrimary : p.textFaint, italic: true)),
            if (trailing != null) ...[const SizedBox(width: 4), trailing!],
          ]),
        ),
      ),
    );
  }
}

/// Two-option segmented control. The selected side is an ink slab, so the
/// current state is unmistakable at a glance.
class Segmented<T> extends StatelessWidget {
  const Segmented({
    super.key,
    required this.options,
    required this.value,
    required this.onChanged,
    this.height = 58,
    this.expand = false,
  });

  final List<(T, String, Widget? Function(Color)?)> options;
  final T value;
  final ValueChanged<T> onChanged;
  final double height;

  /// Share the full width equally instead of sizing to the labels.
  final bool expand;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    Widget cell(Widget child) => expand ? Expanded(child: child) : child;
    return Container(
      height: height,
      decoration: BoxDecoration(
        border: Border.all(color: p.textPrimary, width: 1.2),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        for (final (v, label, icon) in options)
          cell(Semantics(
            button: true,
            selected: v == value,
            label: label,
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => onChanged(v),
              child: Container(
                constraints: BoxConstraints(minWidth: expand ? 0 : 96),
                padding: EdgeInsets.symmetric(horizontal: expand ? 10 : 22),
                color: v == value ? p.textPrimary : Colors.transparent,
                alignment: Alignment.center,
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  if (icon != null) ...[
                    icon(v == value ? p.onInk : p.accent) ?? const SizedBox(),
                    const SizedBox(width: 12),
                  ],
                  Flexible(
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(label,
                          maxLines: 1,
                          style: FolioType.button(v == value ? p.onInk : p.textMuted, size: 19)
                              .copyWith(fontWeight: v == value ? FontWeight.w600 : FontWeight.w400)),
                    ),
                  ),
                ]),
              ),
            ),
          )),
      ]),
    );
  }
}

String formatClock(int ms) {
  final total = ms ~/ 1000;
  final h = total ~/ 3600, m = (total % 3600) ~/ 60, s = total % 60;
  return h > 0
      ? '$h:${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}'
      : '$m:${s.toString().padLeft(2, '0')}';
}

const _roman = [
  (1000, 'M'), (900, 'CM'), (500, 'D'), (400, 'CD'), (100, 'C'), (90, 'XC'),
  (50, 'L'), (40, 'XL'), (10, 'X'), (9, 'IX'), (5, 'V'), (4, 'IV'), (1, 'I'),
];

String roman(int n) {
  final b = StringBuffer();
  var v = n;
  for (final (value, s) in _roman) {
    while (v >= value) {
      b.write(s);
      v -= value;
    }
  }
  return b.toString();
}
