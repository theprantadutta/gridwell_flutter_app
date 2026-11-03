import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../state/online.dart';
import '../../state/privacy.dart';
import '../../state/progress_actions.dart';
import '../../state/settings.dart';
import '../theme/gridwell_theme.dart';
import '../theme/typography.dart';
import '../widgets/folio.dart';
import 'legal_screen.dart';

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

    Widget row(String label, VoidCallback onTap, {bool danger = false, String trailing = '›'}) => Semantics(
          button: true,
          label: label,
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: onTap,
            child: Container(
              decoration: BoxDecoration(border: Border(bottom: BorderSide(color: p.rule))),
              padding: const EdgeInsets.symmetric(vertical: 18),
              child: Row(children: [
                Expanded(
                  child: Text(label,
                      style: FolioType.body(p, size: 20).copyWith(color: danger ? p.accent : null)),
                ),
                Text(trailing, style: FolioType.style(size: 20, color: p.textMuted)),
              ]),
            ),
          ),
        );

    return Scaffold(
      body: FolioBody(
        child: Column(children: [
          const FolioHeader(leading: 'Settings', center: 'Privacy'),
          Expanded(
            child: ListView(padding: const EdgeInsets.fromLTRB(folioMargin, 20, folioMargin, 32), children: [
              Text(
                'Gridwell works fully offline and never asks for your name or location. '
                'Online, it uses an anonymous ID to sync progress and keep daily leaderboards. '
                'Signing in with Google or email is optional and only keeps your progress safe.',
                style: FolioType.bodyMuted(p, size: 17),
              ),
              if (penName != null) ...[
                const SizedBox(height: 12),
                Text('Your pen name: $penName', style: FolioType.body(p, size: 16)),
              ],
              const SizedBox(height: 18),
              Text('DOCUMENTS', style: FolioType.kicker(p)),
              for (final doc in LegalDoc.values) row(doc.title, () => context.push('/legal/${doc.name}')),
              const SizedBox(height: 22),
              Text('YOUR CHOICES', style: FolioType.kicker(p)),
              Semantics(
                toggled: s.shareAnalytics,
                label: 'Share anonymous usage statistics',
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () => ref.read(privacyActionsProvider).setShareAnalytics(!s.shareAnalytics),
                  child: Container(
                    decoration: BoxDecoration(border: Border(bottom: BorderSide(color: p.rule))),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    child: Row(children: [
                      Expanded(
                        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text('Share usage statistics', style: FolioType.body(p, size: 20)),
                          const SizedBox(height: 4),
                          Text('Anonymous events that show which puzzles are too hard. Crash reports are separate.',
                              style: FolioType.bodyMuted(p, size: 15)),
                        ]),
                      ),
                      const SizedBox(width: 16),
                      _Check(on: s.shareAnalytics),
                    ]),
                  ),
                ),
              ),
              if (adChoices) row('Ad privacy choices', () => ref.read(privacyActionsProvider).showAdChoices()),
              const SizedBox(height: 22),
              Text('YOUR DATA', style: FolioType.kicker(p)),
              row('Delete my data', () => _confirmDelete(context, ref), danger: true, trailing: 'asks first'),
            ]),
          ),
        ]),
      ),
    );
  }

  Future<void> _confirmDelete(BuildContext context, WidgetRef ref) async {
    final p = context.palette;
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: p.surfaceRaised,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
        title: Text('Delete your data?', style: FolioType.plateTitle(p, size: 26)),
        content: Text(
          'This deletes your account on our server (progress, times, pen name and achievements) and clears '
          'the progress on this device. Purchases stay with your store account and can be restored. '
          'This cannot be undone.',
          style: FolioType.body(p),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: Text('Keep it', style: FolioType.body(p))),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text('Delete', style: FolioType.body(p).copyWith(color: p.accent)),
          ),
        ],
      ),
    );
    if (ok != true || !context.mounted) return;
    final outcome = await ref.read(progressActionsProvider).deleteEverything();
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(outcome == DeleteOutcome.deleted
          ? 'Your data has been deleted.'
          : 'Cleared on this device. We could not reach our server; email prantadutta1997@gmail.com to finish.'),
    ));
  }
}

class _Check extends StatelessWidget {
  const _Check({required this.on});

  final bool on;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Container(
      width: 54,
      height: 30,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: on ? p.textPrimary : Colors.transparent,
        border: Border.all(color: on ? p.textPrimary : p.ruleStrong, width: 1.2),
        borderRadius: BorderRadius.circular(4),
      ),
      alignment: on ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        width: 20,
        height: 20,
        decoration: BoxDecoration(color: on ? p.onInk : p.ruleStrong, borderRadius: BorderRadius.circular(2)),
      ),
    );
  }
}
