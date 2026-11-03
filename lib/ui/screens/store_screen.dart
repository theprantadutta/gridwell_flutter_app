import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../state/monetization.dart';
import '../../state/providers.dart';
import '../../state/services.dart';
import '../theme/gridwell_theme.dart';
import '../theme/typography.dart';
import '../widgets/folio.dart';
import '../widgets/plate_thumb.dart';

/// Remove Ads ($1.99 once) and Premium (monthly / yearly, with trials).
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
    final ent = ref.watch(entitlementsProvider);
    final controller = ref.read(purchaseControllerProvider.notifier);
    final set = ref.watch(puzzleSetProvider);
    final cover = set.puzzles.where((x) => x.id == 'coastline-lighthouse').firstOrNull ?? set.puzzles.first;
    String price(String id) => store.prices[id] ?? '—';
    final canBuy = store.available;

    Widget plan({
      required String id,
      required String title,
      required String detail,
      bool highlight = false,
      bool owned = false,
    }) =>
        Semantics(
          button: true,
          label: '$title, ${price(id)}',
          child: GestureDetector(
            onTap: canBuy && !owned && store.busy == null ? () => controller.buy(id) : null,
            child: Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
              decoration: BoxDecoration(
                color: highlight ? p.textPrimary : Colors.transparent,
                border: Border.all(color: highlight ? p.textPrimary : p.ruleStrong, width: 1.2),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Row(children: [
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(title, style: FolioType.button(highlight ? p.onInk : p.textPrimary, size: 19)),
                    const SizedBox(height: 4),
                    Text(detail,
                        style: FolioType.style(
                            size: 14.5, italic: true, color: highlight ? p.onInk.withValues(alpha: 0.75) : p.textMuted)),
                  ]),
                ),
                const SizedBox(width: 12),
                store.busy == id
                    ? SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2, color: highlight ? p.onInk : p.textPrimary),
                      )
                    : Text(owned ? 'Yours' : price(id),
                        style: FolioType.button(highlight ? p.onInk : p.textPrimary, size: 19)),
              ]),
            ),
          ),
        );

    return Scaffold(
      body: SafeArea(
        child: Column(children: [
          const FolioHeader(leading: 'Settings'),
          Expanded(
            child: ListView(padding: const EdgeInsets.fromLTRB(folioMargin, 24, folioMargin, 32), children: [
              Center(
                child: Container(
                  width: 150,
                  decoration: BoxDecoration(border: Border.all(color: p.textPrimary, width: 1.2)),
                  padding: const EdgeInsets.all(8),
                  child: PlateThumb(puzzle: cover, state: PlateState.solved),
                ),
              ),
              const SizedBox(height: 22),
              Center(child: Text('THE WHOLE BOOK', style: FolioType.kicker(p))),
              const SizedBox(height: 8),
              Center(
                child: Text('Gridwell, uninterrupted',
                    textAlign: TextAlign.center, style: FolioType.plateTitle(p, size: 36).copyWith(fontWeight: FontWeight.w400)),
              ),
              const SizedBox(height: 10),
              Text(
                'Premium removes every ad, gives you unlimited hints, opens missed dailies for free, '
                'and brings new collections to you first.',
                textAlign: TextAlign.center,
                style: FolioType.body(p, size: 18).copyWith(color: p.textMuted),
              ),
              const SizedBox(height: 22),
              if (!canBuy)
                Padding(
                  padding: const EdgeInsets.only(bottom: 14),
                  child: Text(
                    'Purchases open once Gridwell is live in your store. Everything else works now.',
                    textAlign: TextAlign.center,
                    style: FolioType.bodyMuted(p, size: 15.5),
                  ),
                ),
              plan(
                id: ProductIds.premiumYearly,
                title: 'Premium, yearly',
                detail: 'Best value · free trial, then billed yearly',
                highlight: true,
                owned: ent.premium,
              ),
              plan(
                id: ProductIds.premiumMonthly,
                title: 'Premium, monthly',
                detail: 'Free trial, then billed monthly',
                owned: ent.premium,
              ),
              plan(
                id: ProductIds.removeAds,
                title: 'Remove ads',
                detail: 'One payment. No ads between puzzles, for good.',
                owned: ent.removeAds || ent.premium,
              ),
              if (store.message != null)
                Padding(
                  padding: const EdgeInsets.only(top: 4, bottom: 8),
                  child: Text(store.message!, textAlign: TextAlign.center, style: FolioType.body(p, size: 16)),
                ),
              Center(
                child: TextAction(
                  label: store.busy == 'restore' ? 'Restoring…' : 'Restore purchase',
                  onPressed: store.busy == null ? controller.restore : null,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                'Payment is charged to your Google Play or App Store account. Subscriptions renew automatically '
                'unless cancelled at least 24 hours before the end of the current period, and you can manage or '
                'cancel them in your store account settings. Any unused part of a free trial ends when you subscribe.',
                textAlign: TextAlign.center,
                style: FolioType.style(size: 12.5, color: p.textMuted, height: 1.4),
              ),
              const SizedBox(height: 8),
              Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                TextAction(label: 'Terms', onPressed: () => context.push('/legal/terms')),
                const SizedBox(width: 24),
                TextAction(label: 'Privacy', onPressed: () => context.push('/legal/privacy')),
                const SizedBox(width: 24),
                TextAction(label: 'Refunds', onPressed: () => context.push('/legal/refund')),
              ]),
            ]),
          ),
        ]),
      ),
    );
  }
}
