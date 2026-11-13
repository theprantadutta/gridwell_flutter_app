import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../state/online.dart';
import '../../state/privacy.dart';
import '../../state/progress_actions.dart';
import '../../state/settings.dart';
import '../theme/gridwell_theme.dart';
import '../theme/typography.dart';
import '../widgets/tally.dart';
import 'legal_screen.dart';
import 'settings_screen.dart' show TallyDialogText, showTallyDialog;

/// Settings > Privacy: the documents, analytics choice, ad choices (where
/// required) and deleting your data.
class PrivacyScreen extends ConsumerWidget {
  const PrivacyScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final p = context.palette;
    final s = ref.watch(settingsProvider);
    final adChoices = ref.watch(adChoicesAvailableProvider).value ?? false;
    final penName = ref.watch(penNameProvider);

    return Scaffold(
      body: TallyBody(
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          const TallyTopBar(title: 'Privacy'),
          Expanded(
            child: ListView(padding: const EdgeInsets.only(bottom: 20), children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(tallyMargin, 14, tallyMargin, 0),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(
                    'Gridwell works fully offline and never asks for your name or location. '
                    'Online, it uses an anonymous ID to sync progress and keep daily leaderboards. '
                    'Signing in with Google or email is optional and only keeps your progress safe.',
                    style: TallyType.prose(p.ink2, size: 15).copyWith(height: 1.5),
                  ),
                  if (penName != null) ...[
                    const SizedBox(height: 12),
                    Text('Your pen name: $penName', style: TallyType.body(p.ink).copyWith(fontSize: 15)),
                  ],
                ]),
              ),
              SettingsGroup(title: 'Documents', children: [
                for (final doc in LegalDoc.values)
                  SettingsRow.link(label: doc.title, onTap: () => context.push('/legal/${doc.name}')),
              ]),
              SettingsGroup(title: 'Your choices', children: [
                SettingsRow.toggle(
                  label: 'Share usage statistics',
                  detail: 'Anonymous events that show which puzzles are too hard. Crash reports are separate.',
                  value: s.shareAnalytics,
                  onChanged: (v) => ref.read(privacyActionsProvider).setShareAnalytics(v),
                ),
                if (adChoices)
                  SettingsRow.link(label: 'Ad privacy choices', onTap: () => ref.read(privacyActionsProvider).showAdChoices()),
              ]),
              SettingsGroup(title: 'Your data', children: [
                SettingsRow.link(label: 'Delete my data', labelColor: p.error, onTap: () => _confirmDelete(context, ref)),
              ]),
            ]),
          ),
        ]),
      ),
    );
  }

  Future<void> _confirmDelete(BuildContext context, WidgetRef ref) async {
    final ok = await showTallyDialog<bool>(
      context: context,
      title: 'Delete your data?',
      body: const TallyDialogText(
        'This deletes your account (progress, times, pen name, achievements and, if you signed in, '
        'your email and sign-in) and clears the progress on this device. Purchases stay with your '
        'store account and can be restored. '
        'This cannot be undone.',
      ),
      cancel: 'Keep it',
      confirm: 'Delete',
      destructive: true,
      onConfirm: () => true,
    );
    if (ok != true || !context.mounted) return;
    final outcome = await ref.read(progressActionsProvider).deleteEverything();
    if (!context.mounted) return;
    tallyToast(
      context,
      outcome == DeleteOutcome.deleted
          ? 'Your data has been deleted.'
          : 'Cleared on this device. We could not reach our server; email prantadutta1997@gmail.com to finish.',
    );
  }
}
