import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../state/app_info.dart';
import '../../state/providers.dart';
import '../theme/gridwell_theme.dart';
import '../theme/typography.dart';
import '../widgets/gridwell_mark.dart';
import '../widgets/tally.dart';

/// About Gridwell: what the game is, which version this is, and who made it.
class AboutScreen extends ConsumerWidget {
  const AboutScreen({super.key});

  static final _portfolio = Uri.parse('https://pranta.dev');

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final p = context.palette;
    final info = ref.watch(appInfoProvider).value;
    final set = ref.watch(puzzleSetProvider);
    final collections = set.collections.length;

    Future<void> openPortfolio() async {
      final opened = await ref.read(linkServiceProvider).open(_portfolio);
      if (!opened && context.mounted) tallyToast(context, 'Could not open pranta.dev. Please try again.');
    }

    return Scaffold(
      body: TallyBody(
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          const TallyTopBar(title: 'About'),
          Expanded(
            child: ListView(padding: const EdgeInsets.only(bottom: 28), children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(tallyMargin, 18, tallyMargin, 0),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Row(children: const [
                    GridwellMark(size: 56),
                    SizedBox(width: 16),
                    GridwellWordmark(size: 38),
                  ]),
                  const SizedBox(height: 14),
                  Overline('Nonogram · Picross', color: p.accent),
                  const SizedBox(height: 18),
                  Text(
                    'Gridwell is a picture logic puzzle. Fill the grid using the number clues beside '
                    'each row and above each column, and a picture appears.',
                    style: TallyType.prose(p.ink, size: 17),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Every puzzle can be solved by logic alone, with no guessing, and the whole game '
                    'works offline. Hints show their reasoning, so you learn as you play.',
                    style: TallyType.prose(p.ink2, size: 15),
                  ),
                ]),
              ),
              SettingsGroup(title: 'This version', children: [
                _Fact(label: 'Version', value: info?.version ?? '…'),
                _Fact(label: 'Build', value: info?.build ?? '…'),
                _Fact(
                  label: 'Puzzles',
                  value: '${set.puzzles.length} in $collections ${collections == 1 ? 'collection' : 'collections'}',
                ),
                const _Fact(label: 'Daily', value: 'A new puzzle every day'),
              ]),
              SettingsGroup(title: 'Made by', children: [
                const SettingsRow(label: 'Pranta Dutta', detail: 'Designed and built Gridwell'),
                SettingsRow.link(label: 'pranta.dev', detail: 'Portfolio and other work', onTap: openPortfolio),
              ]),
              SettingsGroup(title: 'More', children: [
                SettingsRow.link(
                  label: 'Open-source licenses',
                  onTap: () => showLicensePage(
                    context: context,
                    applicationName: 'Gridwell',
                    applicationVersion: info == null ? null : '${info.version} (${info.build})',
                  ),
                ),
                SettingsRow.link(label: 'Privacy', onTap: () => context.push('/privacy')),
              ]),
            ]),
          ),
        ]),
      ),
    );
  }
}

/// A label with its value on the right, on a settings row.
class _Fact extends StatelessWidget {
  const _Fact({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return SettingsRow(
      label: label,
      trailing: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 220),
        child: Text(value, textAlign: TextAlign.right, style: TallyType.label(p.ink2).copyWith(fontSize: 14)),
      ),
    );
  }
}
