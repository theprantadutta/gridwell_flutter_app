import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../state/monetization.dart';
import '../../state/services.dart';
import '../theme/gridwell_theme.dart';
import '../theme/typography.dart';
import '../widgets/tally.dart';

/// Remove Ads ($1.99 once), with Premium (monthly / yearly, with trials)
/// beneath it.
class StoreScreen extends ConsumerStatefulWidget {
  const StoreScreen({super.key, this.restoreOnOpen = false});

  final bool restoreOnOpen;

  @override
  ConsumerState<StoreScreen> createState() => _StoreScreenState();
}

class _StoreScreenState extends ConsumerState<StoreScreen> {
  @override
  void initState() {
    super.initState();
    if (widget.restoreOnOpen) {
      WidgetsBinding.instance.addPostFrameCallback((_) => ref.read(purchaseControllerProvider.notifier).restore());
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final store = ref.watch(purchaseControllerProvider);
    // Purchases and restores also say how they went at the foot of the screen.
    ref.listen(purchaseControllerProvider.select((s) => s.message), (previous, message) {
      if (message != null && message != previous) tallyToast(context, message);
    });
    final ent = ref.watch(entitlementsProvider);
    final controller = ref.read(purchaseControllerProvider.notifier);
    final canBuy = store.available;
    final idle = store.busy == null;
    final adPrice = store.prices[ProductIds.removeAds];
    final adsGone = ent.removeAds || ent.premium;

    Widget plan({required String id, required String title, required String detail}) {
      final price = store.prices[id];
      return SettingsRow(
        label: title,
        detail: detail,
        onTap: canBuy && !ent.premium && idle ? () => controller.buy(id) : null,
        trailing: store.busy == id
            ? SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: p.ink))
            : ent.premium
                ? Text('Yours', style: TallyType.label(p.accent).copyWith(fontWeight: FontWeight.w800))
                : price == null
                    ? null
                    : Container(
                        color: p.lime,
                        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 7),
                        child: Text(price, style: TallyType.label(p.onLime).copyWith(fontWeight: FontWeight.w900, height: 1)),
                      ),
      );
    }

    Widget link(String label, String route) => Semantics(
          button: true,
          label: label,
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () => context.push(route),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 6),
              child: Text(label, style: TallyType.label(p.ink2).copyWith(decoration: TextDecoration.underline)),
            ),
          ),
        );

    return Scaffold(
      body: TallyBody(
        bottom: false,
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          TallyTopBar(
            title: 'Remove ads',
            showBack: false,
            trailing: Semantics(
              button: true,
              label: 'Close',
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () => Navigator.of(context).maybePop(),
                child: SizedBox(
                  width: tallyHit,
                  height: tallyHit,
                  child: CustomPaint(painter: _CrossPainter(p.ink2)),
                ),
              ),
            ),
          ),
          Expanded(
            child: ListView(padding: const EdgeInsets.only(bottom: 12), children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(tallyMargin, 28, tallyMargin, 0),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Overline('Gridwell · ad free', color: p.accent),
                  const SizedBox(height: 14),
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Text(
                      adsGone ? 'Yours' : (adPrice ?? 'Ad free'),
                      maxLines: 1,
                      style: TallyType.displayL(p.ink).copyWith(height: 1),
                    ),
                  ),
                  const SizedBox(height: 18),
                  Text(
                    adsGone ? 'No ads between puzzles on this account. Thank you.' : 'Once. Every puzzle stays the same, just quieter.',
                    style: TallyType.prose(p.ink2, size: 16),
                  ),
                  if (!canBuy) ...[
                    const SizedBox(height: 10),
                    Text(
                      'Purchases open once Gridwell is live in your store. Everything else works now.',
                      style: TallyType.prose(p.ink2, size: 14),
                    ),
                  ],
                ]),
              ),
              const SizedBox(height: 28),
              ColoredBox(
                color: p.sunk,
                child: Column(children: const [
                  _Feature(title: 'No ads, ever', detail: 'Nothing plays between puzzles or after a solve.'),
                  SizedBox(height: tallyDivider),
                  _Feature(title: 'Hints stay earned', detail: 'You still get hints by playing, nothing is paywalled.'),
                  SizedBox(height: tallyDivider),
                  _Feature(title: 'One payment', detail: 'Restores on every device signed in to your store account.'),
                ]),
              ),
              SettingsGroup(title: 'Or go premium', children: [
                plan(
                  id: ProductIds.premiumYearly,
                  title: 'Premium, yearly',
                  detail: 'Best value · free trial, then billed yearly',
                ),
                plan(
                  id: ProductIds.premiumMonthly,
                  title: 'Premium, monthly',
                  detail: 'Free trial, then billed monthly',
                ),
              ]),
              Padding(
                padding: const EdgeInsets.fromLTRB(tallyMargin, 10, tallyMargin, 0),
                child: Text(
                  'Premium removes every ad, gives you unlimited hints, opens missed dailies for free, '
                  'and brings new collections to you first.',
                  style: TallyType.prose(p.ink2, size: 13),
                ),
              ),
              if (store.message != null)
                Padding(
                  padding: const EdgeInsets.fromLTRB(tallyMargin, 16, tallyMargin, 0),
                  child: Text(store.message!, textAlign: TextAlign.center, style: TallyType.body(p.ink)),
                ),
              const SizedBox(height: 14),
              Center(
                child: Semantics(
                  button: true,
                  label: 'Restore purchase',
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: idle ? controller.restore : null,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                      child: Text(store.busy == 'restore' ? 'Restoring…' : 'Restore purchase',
                          style: TallyType.body(p.ink2).copyWith(fontSize: 15)),
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: tallyMargin),
                child: Text(
                  'Payment is charged to your Google Play or App Store account. Subscriptions renew automatically '
                  'unless canceled at least 24 hours before the end of the current period, and you can manage or '
                  'cancel them in your store account settings. Any unused part of a free trial ends when you subscribe.',
                  textAlign: TextAlign.center,
                  style: TallyType.label(p.ink3).copyWith(fontSize: 11.5),
                ),
              ),
              Wrap(alignment: WrapAlignment.center, spacing: 18, children: [
                link('Terms', '/legal/terms'),
                link('Privacy', '/legal/privacy'),
                link('Refunds', '/legal/refund'),
              ]),
            ]),
          ),
          if (adsGone)
            PrimarySlab(label: 'Ads removed', sublabel: 'Thank you for supporting Gridwell', onPressed: () => Navigator.of(context).maybePop(), arrow: false, height: 78)
          else
            PrimarySlab(
              label: store.busy == ProductIds.removeAds ? 'One moment…' : 'Remove ads',
              sublabel: adPrice == null ? 'One-time purchase' : 'One-time purchase · $adPrice',
              onPressed: canBuy && idle ? () => controller.buy(ProductIds.removeAds) : null,
              height: 78,
            ),
        ]),
      ),
    );
  }
}

/// A feature row: lime square, title, detail, on `--surface`.
class _Feature extends StatelessWidget {
  const _Feature({required this.title, required this.detail});

  final String title;
  final String detail;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Container(
      color: p.surface,
      padding: const EdgeInsets.fromLTRB(tallyMargin, 18, tallyMargin, 18),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Padding(padding: const EdgeInsets.only(top: 3), child: Container(width: 14, height: 14, color: p.lime)),
        const SizedBox(width: 14),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(title, style: TallyType.bodyL(p.ink).copyWith(fontSize: 17)),
            const SizedBox(height: 6),
            Text(detail, style: TallyType.prose(p.ink2, size: 14)),
          ]),
        ),
      ]),
    );
  }
}

class _CrossPainter extends CustomPainter {
  _CrossPainter(this.color);

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final c = size.center(Offset.zero);
    const h = 6.5;
    final paint = Paint()
      ..color = color
      ..strokeWidth = 2.4
      ..strokeCap = StrokeCap.square;
    canvas.drawLine(c - const Offset(h, h), c + const Offset(h, h), paint);
    canvas.drawLine(c + const Offset(h, -h), c + const Offset(-h, h), paint);
  }

  @override
  bool shouldRepaint(_CrossPainter old) => old.color != color;
}
