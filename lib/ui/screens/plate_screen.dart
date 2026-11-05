import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../state/providers.dart';
import '../theme/gridwell_theme.dart';
import '../theme/typography.dart';
import '../widgets/folio.dart';
import '../widgets/plate_thumb.dart';

/// A solved picture shown large, as a plate in a book.
class PlateScreen extends ConsumerWidget {
  const PlateScreen({super.key, required this.puzzleId});

  final String puzzleId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final p = context.palette;
    final set = ref.watch(puzzleSetProvider);
    final x = set.puzzles.firstWhere((e) => e.id == puzzleId);
    final progress = ref.watch(progressProvider).value?[puzzleId];
    final collection = set.collections.firstWhere((c) => c.id == x.collectionId);
    return Scaffold(
      body: FolioBody(
        child: Column(
          children: [
            FolioHeader(leading: 'Gallery', center: collection.name),
            Expanded(
              child: FolioFillPage(
                minHeight: 560,
                child: Padding(
                  padding: const EdgeInsets.all(folioMargin),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Expanded(
                        child: Container(
                          decoration: BoxDecoration(border: Border.all(color: p.textPrimary, width: 1.2)),
                          padding: const EdgeInsets.all(12),
                          child: Container(
                            color: p.surfaceRaised,
                            padding: const EdgeInsets.all(28),
                            child: Center(
                              child: AspectRatio(
                                aspectRatio: x.width / x.height,
                                child: CustomPaint(
                                  painter: PicturePainter(puzzle: x, palette: p),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      Center(child: Text('PLATE ${roman(x.plateNumber)}', style: FolioType.kicker(p))),
                      const SizedBox(height: 8),
                      Center(
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(x.name, maxLines: 1, style: FolioType.plateTitle(p, size: 44)),
                        ),
                      ),
                      const SizedBox(height: 20),
                      const Hairline(),
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        child: Row(
                          children: [
                            _Fact(label: 'SIZE', value: '${x.width} × ${x.height}'),
                            _Fact(
                              label: 'BEST TIME',
                              value: progress?.bestTimeMs == null ? '–' : formatClock(progress!.bestTimeMs!),
                            ),
                            _Fact(
                              label: 'SOLVED',
                              value: progress?.solveCount == 1 ? 'once' : '${progress?.solveCount ?? 0} times',
                            ),
                          ],
                        ),
                      ),
                      const Hairline(),
                      const SizedBox(height: 20),
                      OutlineButtonFolio(label: 'Solve again', onPressed: () => context.push('/play/${x.id}')),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Fact extends StatelessWidget {
  const _Fact({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Expanded(
      child: Column(
        children: [
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(label, maxLines: 1, style: FolioType.kicker(p)),
          ),
          const SizedBox(height: 6),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(value, maxLines: 1, style: FolioType.body(p, size: 19)),
          ),
        ],
      ),
    );
  }
}
