import 'package:flutter/material.dart';

import '../theme/gridwell_theme.dart';
import '../theme/typography.dart';
import 'gridwell_mark.dart';

/// Horizontal page margin used across Folio screens.
const folioMargin = 24.0;

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
        SizedBox(
          height: 52,
          child: Row(children: [
            Expanded(
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
                            child: Text('‹ ${leading!}', style: style),
                          ),
                        ),
                      ),
              ),
            ),
            if (center != null) Text(center!, style: style),
            Expanded(
              child: Align(
                alignment: Alignment.centerRight,
                child: trailing ?? const SizedBox(),
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
        SizedBox(
          height: 52,
          child: Row(children: [
            const GridwellMark(size: 20), // the logo kit's minimum mark size
            const SizedBox(width: 10),
            Text('GRIDWELL', style: FolioType.wordmark(p)),
            const Spacer(),
            if (trailing != null) Text(trailing!, style: FolioType.header(p)),
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
          child: Row(children: [
            Text(label, style: FolioType.button(p.onInk, size: 19)),
            const Spacer(),
            if (detail != null)
              Text(detail!, style: FolioType.style(size: 16, color: p.onInk.withValues(alpha: 0.75))),
          ]),
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
