import 'package:material_ui/material_ui.dart';

import '../theme/gridwell_theme.dart';
import '../theme/typography.dart';

/// Shared Tally components (`DESIGN-SPEC.md` sections 4 and 6).
///
/// Square, never rounded. Edge to edge. Stacked slabs are separated by a 1 pt
/// `--sunk` gap, never by margins or shadows. Lime marks the one thing to press.

/// Page side margin.
const tallyMargin = 20.0;

/// The 1 pt divider between stacked slabs.
const tallyDivider = 1.0;

/// Minimum hit target for every control outside the board.
const tallyHit = 44.0;

/// A page that fills the screen: [child] gets at least [minHeight] of real
/// height to share out with Expanded and spacing. On short screens or with
/// large text the page keeps [minHeight] and scrolls instead of squeezing.
class TallyFillPage extends StatelessWidget {
  const TallyFillPage({super.key, required this.minHeight, required this.child});

  final double minHeight;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final scaled = MediaQuery.textScalerOf(context).scale(minHeight);
    return LayoutBuilder(
      builder: (context, c) => SingleChildScrollView(
        child: SizedBox(height: c.maxHeight > scaled ? c.maxHeight : scaled, child: child),
      ),
    );
  }
}

/// Body for pushed screens: a [SafeArea] held to a comfortable width, so
/// tablets get a page rather than rows stretched edge to edge.
class TallyBody extends StatelessWidget {
  const TallyBody({super.key, required this.child, this.maxWidth = 640, this.bottom = true});

  final Widget child;
  final double maxWidth;

  /// Pad for the home indicator. Off when a slab runs to the bottom edge and
  /// pads itself.
  final bool bottom;

  @override
  Widget build(BuildContext context) => SafeArea(
        bottom: bottom,
        child: Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(constraints: BoxConstraints(maxWidth: maxWidth), child: child),
        ),
      );
}

/// Press feedback without ripples: [color] at rest, `--track` while pressed.
class Pressable extends StatefulWidget {
  const Pressable({
    super.key,
    required this.child,
    required this.onTap,
    this.color,
    this.pressedColor,
    this.semanticLabel,
    this.selected,
    this.enabled = true,
  });

  final Widget child;
  final VoidCallback? onTap;
  final Color? color;
  final Color? pressedColor;
  final String? semanticLabel;
  final bool? selected;
  final bool enabled;

  @override
  State<Pressable> createState() => _PressableState();
}

class _PressableState extends State<Pressable> {
  var _down = false;

  void _set(bool v) {
    if (_down != v) setState(() => _down = v);
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final active = widget.enabled && widget.onTap != null;
    final rest = widget.color ?? Colors.transparent;
    final pressed = widget.pressedColor ?? (rest == p.lime ? Color.lerp(p.lime, p.onLime, 0.12)! : p.track);
    return Semantics(
      button: true,
      enabled: active,
      selected: widget.selected,
      label: widget.semanticLabel,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: active ? (_) => _set(true) : null,
        onTapUp: active ? (_) => _set(false) : null,
        onTapCancel: active ? () => _set(false) : null,
        onTap: active ? widget.onTap : null,
        child: ColoredBox(color: _down ? pressed : rest, child: widget.child),
      ),
    );
  }
}

/// The 56 pt top bar: back chevron, title, optional size chip, then an
/// optional trailing widget (timer, "VOL. I", close).
class TallyTopBar extends StatelessWidget {
  const TallyTopBar({
    super.key,
    this.title,
    this.chip,
    this.trailing,
    this.onBack,
    this.showBack = true,
    this.titleStyle,
  });

  final String? title;
  final String? chip;
  final Widget? trailing;
  final VoidCallback? onBack;
  final bool showBack;

  /// Defaults to `title-s`.
  final TextStyle? titleStyle;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return SizedBox(
      height: 56,
      child: Padding(
        padding: const EdgeInsets.only(top: 10, right: tallyMargin, left: 6),
        child: Row(children: [
          if (showBack)
            Semantics(
              button: true,
              label: 'Back',
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: onBack ?? () => Navigator.of(context).maybePop(),
                child: SizedBox(
                  width: tallyHit,
                  height: tallyHit,
                  child: CustomPaint(painter: _ChevronPainter(p.ink)),
                ),
              ),
            )
          else
            const SizedBox(width: tallyMargin - 6),
          if (title != null)
            Flexible(
              // Long names shrink a little before they are cut short.
              child: LayoutBuilder(builder: (context, c) {
                final style = titleStyle ?? TallyType.titleS(p.ink);
                final natural = (TextPainter(
                  text: TextSpan(text: title, style: style),
                  textDirection: TextDirection.ltr,
                  textScaler: MediaQuery.textScalerOf(context),
                  maxLines: 1,
                )..layout())
                    .width;
                final scale = natural <= c.maxWidth ? 1.0 : (c.maxWidth / natural).clamp(0.72, 1.0);
                return Text(
                  title!,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: style.copyWith(fontSize: (style.fontSize ?? 22) * scale - (scale < 1 ? 0.5 : 0)),
                );
              }),
            ),
          if (chip != null) ...[const SizedBox(width: 14), SizeChip(chip!)],
          const Spacer(),
          if (trailing != null) ...[const SizedBox(width: 14), trailing!],
        ]),
      ),
    );
  }
}

class _ChevronPainter extends CustomPainter {
  _ChevronPainter(this.color);

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final c = size.center(Offset.zero);
    final path = Path()
      ..moveTo(c.dx + 3, c.dy - 7)
      ..lineTo(c.dx - 4, c.dy)
      ..lineTo(c.dx + 3, c.dy + 7);
    canvas.drawPath(
      path,
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.2
        ..strokeCap = StrokeCap.square,
    );
  }

  @override
  bool shouldRepaint(_ChevronPainter old) => old.color != color;
}

/// "15×15": chip text in a 1.5 pt `--outline` box with a 4 pt radius.
class SizeChip extends StatelessWidget {
  const SizeChip(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 5),
      decoration: BoxDecoration(
        border: Border.all(color: p.outline, width: 1.5),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(text, style: TallyType.chip(p.ink2)),
    );
  }
}

/// Uppercase tracked section label: "DAILY · MON 9 NOV".
class Overline extends StatelessWidget {
  const Overline(this.text, {super.key, this.color});

  final String text;
  final Color? color;

  @override
  Widget build(BuildContext context) =>
      Text(text.toUpperCase(), maxLines: 1, overflow: TextOverflow.ellipsis, style: TallyType.overline(color ?? context.palette.ink2));
}

/// A huge number with a two-line label beside it, bottom-aligned:
/// "45%  68 of 150 / solved".
class BigStat extends StatelessWidget {
  const BigStat({super.key, required this.value, required this.style, this.label, this.labelColor, this.gap = 14, this.trailing});

  /// The number: a [String] or a prebuilt [InlineSpan] for two-tone values
  /// such as "14/30".
  final Object value;
  final TextStyle style;
  final String? label;
  final Color? labelColor;
  final double gap;

  /// Shown instead of a plain label (a "NEW BEST" tag, for example).
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final number = value is InlineSpan
        ? Text.rich(value as InlineSpan, maxLines: 1, style: style)
        : Text('$value', maxLines: 1, style: style);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Flexible(child: FittedBox(fit: BoxFit.scaleDown, alignment: Alignment.bottomLeft, child: number)),
        if (label != null || trailing != null) ...[
          SizedBox(width: gap),
          Padding(
            padding: EdgeInsets.only(bottom: (style.fontSize ?? 60) * 0.06),
            child: trailing ?? Text(label!, maxLines: 3, style: TallyType.label(labelColor ?? p.ink2).copyWith(height: 1.3)),
          ),
        ],
      ],
    );
  }
}

/// The primary slab: lime, full width, uppercase `slab` label, an optional
/// 13 pt sub-label at 80% opacity, and a 30 pt arrow at the right.
class PrimarySlab extends StatelessWidget {
  const PrimarySlab({
    super.key,
    required this.label,
    this.sublabel,
    required this.onPressed,
    this.height = 104,
    this.arrow = true,
    this.bottomInset = true,
    this.uppercase = true,
  });

  final String label;

  /// Slab labels are uppercase; off for labels with a fixed case such as
  /// "START No. 01" (pass them already uppercased where needed).
  final bool uppercase;
  final String? sublabel;
  final VoidCallback? onPressed;
  final double height;
  final bool arrow;

  /// Grow by the home-indicator inset so the slab runs to the bottom edge.
  final bool bottomInset;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final inset = bottomInset ? MediaQuery.paddingOf(context).bottom : 0.0;
    return Pressable(
      color: p.lime,
      onTap: onPressed,
      semanticLabel: sublabel == null ? label : '$label, $sublabel',
      child: Container(
        constraints: BoxConstraints(minHeight: height + inset),
        padding: EdgeInsets.fromLTRB(24, 18, 24, 18 + inset * 0.6),
        child: Row(children: [
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(uppercase ? label.toUpperCase() : label, maxLines: 1, style: TallyType.slab(p.onLime)),
                ),
                if (sublabel != null) ...[
                  const SizedBox(height: 6),
                  Text(
                    sublabel!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TallyType.label(p.onLime.withValues(alpha: 0.8)).copyWith(height: 1),
                  ),
                ],
              ],
            ),
          ),
          if (arrow) ...[const SizedBox(width: 12), TallyArrow(color: p.onLime, size: 30)],
        ]),
      ),
    );
  }
}

/// A right arrow drawn to the kit's proportions.
class TallyArrow extends StatelessWidget {
  const TallyArrow({super.key, required this.color, this.size = 30});

  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) =>
      CustomPaint(size: Size(size, size * 0.8), painter: _ArrowPainter(color, size / 30 * 2.6));
}

class _ArrowPainter extends CustomPainter {
  _ArrowPainter(this.color, this.stroke);

  final Color color;
  final double stroke;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.square;
    final y = size.height / 2;
    final head = size.height * 0.42;
    canvas.drawLine(Offset(stroke / 2, y), Offset(size.width - stroke, y), paint);
    canvas.drawPath(
      Path()
        ..moveTo(size.width - head - stroke / 2, y - head)
        ..lineTo(size.width - stroke / 2, y)
        ..lineTo(size.width - head - stroke / 2, y + head),
      paint,
    );
  }

  @override
  bool shouldRepaint(_ArrowPainter old) => old.color != color || old.stroke != stroke;
}

/// The 44 pt round arrow button on lime slabs: `--on-lime` disc, lime arrow.
class RoundArrow extends StatelessWidget {
  const RoundArrow({super.key, this.size = 44});

  final double size;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(color: p.onLime, shape: BoxShape.circle),
      alignment: Alignment.center,
      child: TallyArrow(color: p.lime, size: size * 0.42),
    );
  }
}

/// A row of equal cells separated by 1 pt `--sunk` gaps: "Undo | Hint",
/// "Replay | Collection".
class SlabRow extends StatelessWidget {
  const SlabRow({super.key, required this.children, this.height = 58});

  final List<Widget> children;
  final double height;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return ColoredBox(
      color: p.sunk,
      child: SizedBox(
        height: MediaQuery.textScalerOf(context).scale(height).clamp(height, height * 1.6),
        child: Row(children: [
          for (var i = 0; i < children.length; i++) ...[
            if (i > 0) const SizedBox(width: tallyDivider),
            Expanded(child: children[i]),
          ],
        ]),
      ),
    );
  }
}

/// One cell of a [SlabRow]: centered `body` label on `--surface`.
class SlabButton extends StatelessWidget {
  const SlabButton({super.key, required this.label, required this.onPressed, this.trailing, this.enabled = true, this.color, this.textColor});

  final String label;
  final VoidCallback? onPressed;
  final Widget? trailing;
  final bool enabled;
  final Color? color;
  final Color? textColor;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Pressable(
      color: color ?? p.surface,
      onTap: onPressed,
      enabled: enabled,
      semanticLabel: label,
      child: Center(
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Flexible(
            child: Text(label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TallyType.body(enabled ? (textColor ?? p.ink) : p.ink3)),
          ),
          if (trailing != null) ...[const SizedBox(width: 8), trailing!],
        ]),
      ),
    );
  }
}

/// Count badge: `chip` weight on `--track`, 10 pt radius.
class CountBadge extends StatelessWidget {
  const CountBadge(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(color: p.track, borderRadius: BorderRadius.circular(10)),
      child: Text(text, style: TallyType.chip(p.ink)),
    );
  }
}

/// Progress ticks: one square per item, 2 pt gaps. Done ticks are [doneColor]
/// (`--ink` by default, lime for the collection you're in); the rest `--track`.
/// [current] gets a lime tick with a ring.
class ProgressTicks extends StatelessWidget {
  const ProgressTicks({
    super.key,
    required this.total,
    required this.done,
    this.doneColor,
    this.current,
    this.height = 9,
    this.flexible = false,
  });

  final int total;

  /// Indices that are done. Order does not matter.
  final Set<int> done;
  final Color? doneColor;
  final int? current;
  final double height;

  /// Fill the full width with flexible ticks (Complete). Otherwise ticks are
  /// square, narrowing only when [total] would not fit.
  final bool flexible;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return LayoutBuilder(builder: (context, c) {
      const gap = 2.0;
      // The ringed current tick is 4 px wider than the rest; take it out of
      // the shared width so flexible rows never overflow.
      final ring = current != null ? 4.0 : 0.0;
      final fit = (c.maxWidth - gap * (total - 1) - ring) / total;
      final w = flexible ? fit : fit.clamp(1.0, height);
      return SizedBox(
        height: height + (current != null ? 4 : 0),
        child: Row(
          children: [
            for (var i = 0; i < total; i++) ...[
              if (i > 0) const SizedBox(width: gap),
              if (i == current)
                Container(
                  width: w + 4,
                  height: height + 4,
                  decoration: BoxDecoration(color: p.lime, border: Border.all(color: p.accent, width: 2)),
                )
              else
                Container(
                  width: w,
                  height: height,
                  color: done.contains(i) ? (doneColor ?? p.ink) : p.track,
                ),
            ],
          ],
        ),
      );
    });
  }
}

/// Square toggle: 52 × 30 track, 24 pt knob, 3 pt inset. On = lime track with
/// an `--on-lime` knob at the right; off = `--track` with an `--ink-2` knob.
class TallyToggle extends StatelessWidget {
  const TallyToggle({super.key, required this.value});

  final bool value;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 140),
      width: 52,
      height: 30,
      padding: const EdgeInsets.all(3),
      color: value ? p.lime : p.track,
      alignment: value ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(width: 24, height: 24, color: value ? p.onLime : p.ink2),
    );
  }
}

/// Segmented control: `--track` container with 3 pt padding; the selected
/// segment is lime with `--on-lime` text.
class TallySegmented<T> extends StatelessWidget {
  const TallySegmented({super.key, required this.options, required this.value, required this.onChanged, this.expand = false});

  final List<(T, String)> options;
  final T value;
  final ValueChanged<T> onChanged;

  /// Share the full width equally instead of sizing to the labels.
  final bool expand;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Container(
      color: p.track,
      padding: const EdgeInsets.all(3),
      child: Row(mainAxisSize: expand ? MainAxisSize.max : MainAxisSize.min, children: [
        for (final (v, label) in options)
          _maybeExpand(
            expand,
            Semantics(
              button: true,
              selected: v == value,
              label: label,
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () => onChanged(v),
                child: Container(
                  constraints: const BoxConstraints(minHeight: 32),
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  color: v == value ? p.lime : Colors.transparent,
                  alignment: Alignment.center,
                  child: Text(label, maxLines: 1, style: TallyType.label(v == value ? p.onLime : p.ink2).copyWith(fontWeight: FontWeight.w800, height: 1)),
                ),
              ),
            ),
          ),
      ]),
    );
  }

  static Widget _maybeExpand(bool expand, Widget child) => expand ? Expanded(child: child) : child;
}

/// A settings group: overline title, then rows separated by 1 pt `--sunk`.
class SettingsGroup extends StatelessWidget {
  const SettingsGroup({super.key, required this.title, required this.children});

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      Padding(
        padding: const EdgeInsets.fromLTRB(tallyMargin, 20, tallyMargin, 10),
        child: Overline(title),
      ),
      ColoredBox(
        color: p.sunk,
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          for (var i = 0; i < children.length; i++) ...[
            if (i > 0) const SizedBox(height: tallyDivider),
            children[i],
          ],
        ]),
      ),
    ]);
  }
}

/// A settings row: label (and optional detail line) on `--surface`, min 50 pt,
/// with a trailing control.
class SettingsRow extends StatelessWidget {
  const SettingsRow({super.key, required this.label, this.detail, this.trailing, this.onTap, this.labelColor, this.selected});

  final String label;
  final String? detail;
  final Widget? trailing;
  final VoidCallback? onTap;
  final Color? labelColor;
  final bool? selected;

  /// A row with a toggle.
  static Widget toggle({required String label, String? detail, required bool value, required ValueChanged<bool> onChanged}) =>
      Builder(
        builder: (context) => MergeSemantics(
          child: Semantics(
            toggled: value,
            child: SettingsRow(label: label, detail: detail, trailing: TallyToggle(value: value), onTap: () => onChanged(!value)),
          ),
        ),
      );

  /// A row that opens something: label and an arrow.
  static Widget link({required String label, String? detail, String? value, required VoidCallback onTap, Color? labelColor}) =>
      Builder(builder: (context) {
        final p = context.palette;
        return SettingsRow(
          label: label,
          detail: detail,
          labelColor: labelColor,
          onTap: onTap,
          trailing: labelColor != null
              ? null
              : Row(mainAxisSize: MainAxisSize.min, children: [
                  if (value != null) ...[
                    ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 160),
                      child: Text(value, maxLines: 1, overflow: TextOverflow.ellipsis, style: TallyType.label(p.ink2)),
                    ),
                    const SizedBox(width: 10),
                  ],
                  TallyArrow(color: p.ink2, size: 14),
                ]),
        );
      });

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Pressable(
      color: p.surface,
      onTap: onTap,
      semanticLabel: detail == null ? label : '$label. $detail',
      selected: selected,
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 50),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: tallyMargin, vertical: 10),
          child: Row(children: [
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
                Text(label, style: TallyType.body(labelColor ?? p.ink).copyWith(fontSize: 17, height: 1.15)),
                if (detail != null) ...[
                  const SizedBox(height: 3),
                  Text(detail!, style: TallyType.label(p.ink2).copyWith(fontSize: 12, height: 1.25)),
                ],
              ]),
            ),
            if (trailing != null) ...[const SizedBox(width: 12), trailing!],
          ]),
        ),
      ),
    );
  }
}

/// Screen title for tab pages: "Daily", "Gallery", "Settings" in `title-l`,
/// with an optional right-aligned caption ("68 pictures").
class TallyPageTitle extends StatelessWidget {
  const TallyPageTitle(this.title, {super.key, this.caption});

  final String title;
  final String? caption;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Padding(
      padding: const EdgeInsets.fromLTRB(tallyMargin, 14, tallyMargin, 0),
      child: Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
        Expanded(child: Text(title, maxLines: 1, style: TallyType.titleL(p.ink))),
        if (caption != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Text(caption!, style: TallyType.label(p.ink2)),
          ),
      ]),
    );
  }
}

/// Section header: `body-l` title, optional link at the right ("ALL 30 →").
class SectionHeader extends StatelessWidget {
  const SectionHeader(this.title, {super.key, this.action, this.onAction});

  final String title;
  final String? action;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Padding(
      padding: const EdgeInsets.fromLTRB(tallyMargin, 22, tallyMargin, 10),
      child: Row(children: [
        Expanded(child: Text(title, maxLines: 1, overflow: TextOverflow.ellipsis, style: TallyType.bodyL(p.ink))),
        if (action != null)
          Semantics(
            button: true,
            label: action,
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: onAction,
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Text('${action!.toUpperCase()} →', style: TallyType.overline(p.ink2).copyWith(fontSize: 12)),
              ),
            ),
          ),
      ]),
    );
  }
}

/// A clock reading with tabular digits (no jitter as it ticks) but a
/// proportional colon: Schibsted's tabular colon is as wide as a digit.
TextSpan clockSpan(String clock, TextStyle style) {
  // An empty list would inherit the parent's tnum; switch it off outright.
  final plain = style.copyWith(fontFeatures: const [FontFeature('tnum', 0)]);
  return TextSpan(children: [
    for (final part in clock.split(RegExp(r'(?=:)|(?<=:)')))
      TextSpan(text: part, style: part == ':' ? plain : style),
  ]);
}

/// A short message saying what just happened (signed in, hint earned,
/// purchase restored). It slides in at the top, under the status bar, so it
/// never covers the slabs at the foot of the screen (FILL, APPLY, NEXT
/// PUZZLE), and a new one replaces the old so they never queue up. Tap to
/// dismiss.
void tallyToast(BuildContext context, String message, {SnackBarAction? action}) {
  final overlay = Overlay.maybeOf(context, rootOverlay: true);
  if (overlay == null) return;
  _TallyToast.current?.remove();
  late final OverlayEntry entry;
  entry = OverlayEntry(
    builder: (_) => _TallyToast(
      message: message,
      action: action,
      onGone: () {
        if (_TallyToast.current == entry) _TallyToast.current = null;
        if (entry.mounted) entry.remove();
      },
    ),
  );
  _TallyToast.current = entry;
  overlay.insert(entry);
}

class _TallyToast extends StatefulWidget {
  const _TallyToast({required this.message, required this.onGone, this.action});

  static OverlayEntry? current;

  final String message;
  final SnackBarAction? action;
  final VoidCallback onGone;

  @override
  State<_TallyToast> createState() => _TallyToastState();
}

class _TallyToastState extends State<_TallyToast> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 220));

  @override
  void initState() {
    super.initState();
    _c.forward();
    Future<void>.delayed(const Duration(seconds: 3), _hide);
  }

  Future<void> _hide() async {
    if (!mounted) return;
    await _c.reverse();
    widget.onGone();
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final curve = CurvedAnimation(parent: _c, curve: Curves.easeOutCubic);
    return Positioned(
      left: 0,
      right: 0,
      top: 0,
      child: SafeArea(
        bottom: false,
        child: Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
              child: FadeTransition(
                opacity: curve,
                child: SlideTransition(
                  position: Tween(begin: const Offset(0, -0.4), end: Offset.zero).animate(curve),
                  child: Material(
                    type: MaterialType.transparency,
                    child: Semantics(
                      liveRegion: true,
                      child: GestureDetector(
                        onTap: _hide,
                        child: Container(
                          color: p.ink,
                          padding: const EdgeInsets.fromLTRB(16, 14, 8, 14),
                          child: Row(children: [
                            Expanded(
                              child: Padding(
                                padding: const EdgeInsets.only(right: 8),
                                child: Text(widget.message, style: TallyType.body(p.bg).copyWith(height: 1.3)),
                              ),
                            ),
                            if (widget.action != null)
                              GestureDetector(
                                onTap: () {
                                  widget.action!.onPressed();
                                  _hide();
                                },
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  child: Text(widget.action!.label.toUpperCase(),
                                      style: TallyType.overline(p.lime).copyWith(fontSize: 13)),
                                ),
                              ),
                          ]),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
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
