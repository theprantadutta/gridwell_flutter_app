import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../state/account.dart';
import '../../state/app_info.dart';
import '../../state/online.dart';
import '../../state/progress_actions.dart';
import '../../state/settings.dart';
import '../theme/gridwell_theme.dart';
import '../theme/typography.dart';
import '../widgets/folio.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final p = context.palette;
    final s = ref.watch(settingsProvider);
    final notifier = ref.read(settingsProvider.notifier);
    final version = ref.watch(appVersionProvider).value;
    final account = ref.watch(accountProvider).value ?? Account.guest;

    Widget section(String title) => Padding(
          padding: const EdgeInsets.only(top: 22, bottom: 4),
          child: Text(title, style: FolioType.kicker(p)),
        );

    return ListView(padding: EdgeInsets.zero, children: [
      const WordmarkHeader(),
      Padding(
        padding: const EdgeInsets.fromLTRB(folioMargin, 28, folioMargin, 24),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Settings', style: FolioType.display(p)),
          section('PLAY'),
          _Toggle(label: 'Sound', value: s.sound, onChanged: (v) => notifier.update((x) => x.copyWith(sound: v))),
          _Toggle(label: 'Haptics', value: s.haptics, onChanged: (v) => notifier.update((x) => x.copyWith(haptics: v))),
          _Toggle(
            label: 'Show proven mistakes',
            detail: 'Flags only a square the clues rule out. It never checks against the answer.',
            value: s.showProvenMistakes,
            onChanged: (v) => notifier.update((x) => x.copyWith(showProvenMistakes: v)),
          ),
          _Toggle(
            label: 'Cross out finished lines',
            detail: 'When a row or column is complete, its empty squares are crossed for you.',
            value: s.autoCross,
            onChanged: (v) => notifier.update((x) => x.copyWith(autoCross: v)),
          ),
          _Toggle(
            label: 'Show the timer',
            detail: 'Your times are still kept when it is hidden.',
            value: s.showTimer,
            onChanged: (v) => notifier.update((x) => x.copyWith(showTimer: v)),
          ),
          _Toggle(
            label: 'Daily reminder',
            detail: 'A quiet note at 7 in the evening if today\'s puzzle is still open.',
            value: s.dailyReminder,
            onChanged: (v) => notifier.update((x) => x.copyWith(dailyReminder: v)),
          ),
          section('APPEARANCE'),
          Padding(
            padding: const EdgeInsets.only(top: 12, bottom: 12),
            child: Text('Theme', style: FolioType.body(p, size: 20)),
          ),
          _ThemeChoice(value: s.themeMode, onChanged: (m) => notifier.update((x) => x.copyWith(themeMode: m))),
          const SizedBox(height: 12),
          const Hairline(),
          _Toggle(
            label: 'High contrast',
            detail: 'Heavier grid lines, full-strength ink.',
            value: s.highContrast,
            onChanged: (v) => notifier.update((x) => x.copyWith(highContrast: v)),
          ),
          section('ACCOUNT'),
          _Row(
            label: account.isGuest ? 'Sign in' : 'Signed in',
            trailing: account.isGuest ? 'keep your progress ›' : (account.email ?? 'your account'),
            onTap: () => context.push('/account'),
          ),
          _Row(
            label: 'Pen name',
            trailing: ref.watch(penNameProvider) ?? 'offline',
            onTap: () => _rename(context, ref),
          ),
          _Row(label: 'Remove ads & premium', trailing: '›', onTap: () => context.push('/store')),
          _Row(label: 'Restore purchase', trailing: '›', onTap: () => context.push('/store?restore=1')),
          _Row(label: 'Privacy & your data', trailing: '›', onTap: () => context.push('/privacy')),
          _Row(
            label: 'Reset progress',
            trailing: 'asks first',
            danger: true,
            onTap: () => _confirmReset(context, ref),
          ),
          const SizedBox(height: 18),
          Center(
            child: Text(version == null ? '' : 'Gridwell $version',
                style: FolioType.style(size: 15, color: p.textMuted)),
          ),
        ]),
      ),
    ]);
  }

  Future<void> _rename(BuildContext context, WidgetRef ref) async {
    final p = context.palette;
    final controller = TextEditingController(text: ref.read(penNameProvider) ?? '');
    final name = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: p.surfaceRaised,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
        title: Text('Your pen name', style: FolioType.plateTitle(p, size: 26)),
        content: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text("Shown on daily leaderboards. Please don't use your real name.", style: FolioType.bodyMuted(p, size: 15)),
          const SizedBox(height: 12),
          TextField(controller: controller, maxLength: 24, autofocus: true, style: FolioType.body(p)),
        ]),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text('Cancel', style: FolioType.body(p))),
          TextButton(
            onPressed: () => Navigator.pop(context, controller.text),
            child: Text('Save', style: FolioType.body(p).copyWith(fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
    if (name == null || name.trim().isEmpty || !context.mounted) return;
    final error = await ref.read(onlineSessionProvider).rename(name);
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error ?? 'Saved.')));
  }

  Future<void> _confirmReset(BuildContext context, WidgetRef ref) async {
    final p = context.palette;
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: p.surfaceRaised,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
        title: Text('Start the book again?', style: FolioType.plateTitle(p, size: 26)),
        content: Text(
          'Every solved plate, best time and board in progress on this device will be cleared. '
          'This cannot be undone.',
          style: FolioType.body(p),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Keep my progress', style: FolioType.body(p)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text('Reset', style: FolioType.body(p).copyWith(color: p.accent)),
          ),
        ],
      ),
    );
    if (ok == true) await ref.read(progressActionsProvider).resetAll();
  }
}

class _Toggle extends StatelessWidget {
  const _Toggle({required this.label, this.detail, required this.value, required this.onChanged});

  final String label;
  final String? detail;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Semantics(
      toggled: value,
      label: label,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => onChanged(!value),
        child: Container(
          decoration: BoxDecoration(border: Border(bottom: BorderSide(color: p.rule))),
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Row(children: [
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(label, style: FolioType.body(p, size: 20)),
                if (detail != null) ...[
                  const SizedBox(height: 4),
                  Text(detail!, style: FolioType.bodyMuted(p, size: 15)),
                ],
              ]),
            ),
            const SizedBox(width: 16),
            _Switch(value: value),
          ]),
        ),
      ),
    );
  }
}

/// A square-cornered switch: ink track with a paper knob when on.
class _Switch extends StatelessWidget {
  const _Switch({required this.value});

  final bool value;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 160),
      width: 54,
      height: 30,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: value ? p.textPrimary : Colors.transparent,
        border: Border.all(color: value ? p.textPrimary : p.ruleStrong, width: 1.2),
        borderRadius: BorderRadius.circular(4),
      ),
      alignment: value ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        width: 20,
        height: 20,
        decoration: BoxDecoration(
          color: value ? p.onInk : p.ruleStrong,
          borderRadius: BorderRadius.circular(2),
        ),
      ),
    );
  }
}

class _ThemeChoice extends StatelessWidget {
  const _ThemeChoice({required this.value, required this.onChanged});

  final ThemeMode value;
  final ValueChanged<ThemeMode> onChanged;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    const options = [(ThemeMode.light, 'Light'), (ThemeMode.dark, 'Dark'), (ThemeMode.system, 'System')];
    return Container(
      height: 56,
      decoration: BoxDecoration(
        border: Border.all(color: p.textPrimary, width: 1.2),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(children: [
        for (var i = 0; i < options.length; i++)
          Expanded(
            child: Semantics(
              button: true,
              selected: options[i].$1 == value,
              label: '${options[i].$2} theme',
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () => onChanged(options[i].$1),
                child: Container(
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: options[i].$1 == value ? p.textPrimary : Colors.transparent,
                    border: i == 0 ? null : Border(left: BorderSide(color: p.textPrimary, width: 0.6)),
                  ),
                  child: Text(options[i].$2,
                      style: FolioType.body(p, size: 19).copyWith(
                        color: options[i].$1 == value ? p.onInk : p.textMuted,
                        fontWeight: options[i].$1 == value ? FontWeight.w600 : FontWeight.w400,
                      )),
                ),
              ),
            ),
          ),
      ]),
    );
  }
}

class _Row extends StatelessWidget {
  const _Row({required this.label, required this.trailing, required this.onTap, this.danger = false});

  final String label;
  final String trailing;
  final VoidCallback onTap;
  final bool danger;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Semantics(
      button: true,
      label: label,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(border: Border(bottom: BorderSide(color: p.rule))),
          padding: const EdgeInsets.symmetric(vertical: 18),
          child: Row(children: [
            Text(label, style: FolioType.body(p, size: 20).copyWith(color: danger ? p.accent : null)),
            const SizedBox(width: 12),
            Expanded(
              child: Text(trailing,
                  textAlign: TextAlign.right,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: trailing.length > 2
                      ? FolioType.bodyMuted(p, size: 16)
                      : FolioType.style(size: 20, color: p.textMuted)),
            ),
          ]),
        ),
      ),
    );
  }
}
