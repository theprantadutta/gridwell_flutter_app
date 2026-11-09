import 'package:flutter/foundation.dart' show TargetPlatform, defaultTargetPlatform;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../state/account.dart';
import '../../state/app_info.dart';
import '../../state/monetization.dart';
import '../../state/online.dart';
import '../../state/progress_actions.dart';
import '../../state/reminders.dart';
import '../../state/services.dart';
import '../../state/settings.dart';
import '../../state/store_prompts.dart';
import '../theme/gridwell_theme.dart';
import '../theme/typography.dart';
import '../widgets/tally.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final p = context.palette;
    final s = ref.watch(settingsProvider);
    final notifier = ref.read(settingsProvider.notifier);
    final version = ref.watch(appVersionProvider).value;
    final account = ref.watch(accountProvider).value ?? Account.guest;
    final ent = ref.watch(entitlementsProvider);
    final removeAdsPrice = ref.watch(purchaseControllerProvider).prices[ProductIds.removeAds];

    void set(Settings Function(Settings) change) => notifier.update(change);

    return ListView(padding: EdgeInsets.zero, children: [
      const TallyPageTitle('Settings'),
      SettingsGroup(title: 'Play', children: [
        SettingsRow.toggle(label: 'Sound', value: s.sound, onChanged: (v) => set((x) => x.copyWith(sound: v))),
        SettingsRow.toggle(label: 'Haptics', value: s.haptics, onChanged: (v) => set((x) => x.copyWith(haptics: v))),
        SettingsRow.toggle(
          label: 'Show proven mistakes',
          detail: 'Flags a square the clues rule out',
          value: s.showProvenMistakes,
          onChanged: (v) => set((x) => x.copyWith(showProvenMistakes: v)),
        ),
        SettingsRow.toggle(
          label: 'Auto-cross finished lines',
          value: s.autoCross,
          onChanged: (v) => set((x) => x.copyWith(autoCross: v)),
        ),
        SettingsRow.toggle(
          label: 'Show the timer',
          detail: 'Times are still kept when it is hidden',
          value: s.showTimer,
          onChanged: (v) => set((x) => x.copyWith(showTimer: v)),
        ),
        SettingsRow.toggle(
          label: 'Daily reminder',
          detail: "At 7 pm, if today's puzzle is still open",
          value: s.dailyReminder,
          onChanged: (v) async {
            if (!v) {
              set((x) => x.copyWith(dailyReminder: false));
              tallyToast(context, 'Daily reminder off.');
              return;
            }
            // Turning it on asks for notification permission if needed.
            final granted = await ref.read(reminderSchedulerProvider).optIn();
            if (!context.mounted) return;
            tallyToast(
              context,
              granted
                  ? "Daily reminder on. A note at 7 pm when the day's puzzle is still open."
                  : 'Notifications are off for Gridwell. Allow them in system settings to get the reminder.',
            );
          },
        ),
        SettingsRow.link(
          label: 'Show walkthrough again',
          onTap: () {
            set((x) => x.copyWith(boardTourDone: false));
            tallyToast(context, 'The walkthrough will play on your next puzzle.');
          },
        ),
      ]),
      SettingsGroup(title: 'Look', children: [
        SettingsRow(
          label: 'Theme',
          trailing: TallySegmented<ThemeMode>(
            options: const [(ThemeMode.system, 'System'), (ThemeMode.light, 'Light'), (ThemeMode.dark, 'Dark')],
            value: s.themeMode,
            onChanged: (m) => set((x) => x.copyWith(themeMode: m)),
          ),
        ),
        SettingsRow.toggle(
          label: 'High contrast',
          value: s.highContrast,
          onChanged: (v) => set((x) => x.copyWith(highContrast: v)),
        ),
      ]),
      SettingsGroup(title: 'Account', children: [
        SettingsRow.link(
          label: account.isGuest ? 'Sign in' : 'Signed in',
          detail: account.isGuest ? 'Keep your progress on every device' : null,
          value: account.isGuest ? null : (account.email ?? 'Your account'),
          onTap: () => context.push('/account'),
        ),
        SettingsRow.link(
          label: 'Pen name',
          value: ref.watch(penNameProvider) ?? 'Offline',
          onTap: () => _rename(context, ref),
        ),
      ]),
      SettingsGroup(title: 'Purchases', children: [
        SettingsRow(
          label: ent.premium ? 'Premium' : 'Remove ads',
          detail: ent.premium
              ? 'Everything unlocked. Thank you.'
              : ent.removeAds
                  ? 'Ads are gone. Premium adds unlimited hints.'
                  : null,
          onTap: () => context.push('/store'),
          trailing: ent.premium || ent.removeAds
              ? TallyArrow(color: p.ink2, size: 14)
              : removeAdsPrice == null
                  ? TallyArrow(color: p.ink2, size: 14)
                  : _PriceTag(removeAdsPrice),
        ),
        SettingsRow.link(label: 'Restore purchase', onTap: () => context.push('/store?restore=1')),
      ]),
      SettingsGroup(title: 'About', children: [
        if (defaultTargetPlatform == TargetPlatform.android)
          SettingsRow.link(label: 'Check for updates', onTap: () => _checkForUpdates(context, ref)),
        SettingsRow.link(label: 'Privacy', onTap: () => context.push('/privacy')),
        SettingsRow.link(label: 'Reset progress', labelColor: p.error, onTap: () => _confirmReset(context, ref)),
      ]),
      Padding(
        padding: const EdgeInsets.fromLTRB(tallyMargin, 16, tallyMargin, 24),
        child: Text(
          version == null ? 'Gridwell · pranta.dev' : 'Gridwell $version · pranta.dev',
          style: TallyType.label(p.ink3),
        ),
      ),
    ]);
  }

  Future<void> _rename(BuildContext context, WidgetRef ref) async {
    final p = context.palette;
    final controller = TextEditingController(text: ref.read(penNameProvider) ?? '');
    final name = await showTallyDialog<String>(
      context: context,
      title: 'Your pen name',
      body: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text("Shown on daily leaderboards. Please don't use your real name.", style: TallyType.prose(p.ink2, size: 14)),
        const SizedBox(height: 14),
        TextField(controller: controller, maxLength: 24, autofocus: true, style: TallyType.body(p.ink)),
      ]),
      cancel: 'Cancel',
      confirm: 'Save',
      onConfirm: () => controller.text,
    );
    if (name == null || name.trim().isEmpty || !context.mounted) return;
    final error = await ref.read(onlineSessionProvider).rename(name);
    if (!context.mounted) return;
    tallyToast(context, error ?? 'Pen name saved.');
  }

  Future<void> _confirmReset(BuildContext context, WidgetRef ref) async {
    final ok = await showTallyDialog<bool>(
      context: context,
      title: 'Start again from the beginning?',
      body: const TallyDialogText(
        'Every solved puzzle, best time and board in progress on this device will be cleared. '
        'This cannot be undone.',
      ),
      cancel: 'Keep my progress',
      confirm: 'Reset',
      destructive: true,
      onConfirm: () => true,
    );
    if (ok == true) {
      await ref.read(progressActionsProvider).resetAll();
      if (context.mounted) tallyToast(context, 'Progress reset. Every puzzle is fresh again.');
    }
  }
}

Future<void> _checkForUpdates(BuildContext context, WidgetRef ref) async {
  final updates = ref.read(updateReadyProvider.notifier);
  tallyToast(context, 'Checking for updates…');
  final result = await updates.check(manual: true);
  if (!context.mounted) return;
  switch (result) {
    case UpdateCheck.upToDate:
      tallyToast(context, 'You have the latest version.');
    case UpdateCheck.ready:
      tallyToast(context, 'An update is ready.', action: SnackBarAction(label: 'Restart', onPressed: updates.install));
    case UpdateCheck.failed:
      tallyToast(context, 'Could not check. Updates come through Google Play.');
    case UpdateCheck.offered:
      break; // Google Play shows its own screen.
  }
}

/// "$1.99" on a lime tag.
class _PriceTag extends StatelessWidget {
  const _PriceTag(this.price);

  final String price;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Container(
      color: p.lime,
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 7),
      child: Text(price, style: TallyType.label(p.onLime).copyWith(fontWeight: FontWeight.w900, height: 1)),
    );
  }
}

/// Body copy for [showTallyDialog].
class TallyDialogText extends StatelessWidget {
  const TallyDialogText(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) => Text(text, style: TallyType.prose(context.palette.ink2, size: 14));
}

/// A Tally dialog: square, `--surface`, Black title, then two slabs at its
/// foot. The confirm slab is lime, or `--error` when [destructive]. Returns
/// [onConfirm]'s value, or null when cancelled.
Future<T?> showTallyDialog<T>({
  required BuildContext context,
  required String title,
  required Widget body,
  required String cancel,
  required String confirm,
  required T Function() onConfirm,
  bool destructive = false,
}) =>
    showDialog<T>(
      context: context,
      builder: (context) {
        final p = context.palette;
        return Dialog(
          backgroundColor: p.surface,
          shape: const RoundedRectangleBorder(),
          insetPadding: const EdgeInsets.symmetric(horizontal: tallyMargin, vertical: 24),
          clipBehavior: Clip.hardEdge,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 440),
            child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
              Flexible(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(tallyMargin, 22, tallyMargin, 20),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(title, style: TallyType.titleS(p.ink).copyWith(fontWeight: FontWeight.w900, height: 1.1)),
                    const SizedBox(height: 12),
                    body,
                  ]),
                ),
              ),
              SlabRow(height: 54, children: [
                SlabButton(label: cancel, color: p.track, onPressed: () => Navigator.pop(context)),
                SlabButton(
                  label: confirm,
                  color: destructive ? p.error : p.lime,
                  textColor: destructive ? p.onError : p.onLime,
                  onPressed: () => Navigator.pop(context, onConfirm()),
                ),
              ]),
            ]),
          ),
        );
      },
    );
