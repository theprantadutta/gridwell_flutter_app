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
        child: Column(children: [
          FolioHeader(leading: 'Gallery', center: collection.name),
          Expanded(
            child: ListView(padding: const EdgeInsets.all(folioMargin), children: [
              Container(
                decoration: BoxDecoration(border: Border.all(color: p.textPrimary, width: 1.2)),
                padding: const EdgeInsets.all(12),
                child: Container(
                  color: p.surfaceRaised,
                  padding: const EdgeInsets.all(28),
                  child: AspectRatio(
                    aspectRatio: x.width / x.height,
                    child: CustomPaint(painter: PicturePainter(puzzle: x, palette: p)),
                  ),
                ),
              ),
              const SizedBox(height: 28),
              Center(child: Text('PLATE ${roman(x.plateNumber)}', style: FolioType.kicker(p))),
              const SizedBox(height: 8),
              Center(child: Text(x.name, style: FolioType.plateTitle(p, size: 44))),
              const SizedBox(height: 10),
              if (progress?.bestTimeMs != null)
                Center(
                  child: Text('Best time ${formatClock(progress!.bestTimeMs!)} · ${x.width} × ${x.height}',
                      style: FolioType.bodyMuted(p, size: 18)),
                ),
              const SizedBox(height: 28),
              OutlineButtonFolio(label: 'Solve again', onPressed: () => context.push('/play/${x.id}')),
            ]),
          ),
        ]),
      ),
    );
  }
}
