import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;

import '../theme/gridwell_theme.dart';
import '../theme/typography.dart';
import '../widgets/folio.dart';

/// Legal documents bundled in assets/legal (also served at
/// `legal.pranta.dev/gridwell/<doc>`).
enum LegalDoc {
  privacy('Privacy Policy', 'assets/legal/PRIVACY.md'),
  terms('Terms of Use', 'assets/legal/TERMS.md'),
  refund('Refund Policy', 'assets/legal/REFUND.md');

  const LegalDoc(this.title, this.asset);
  final String title;
  final String asset;
}

/// Reads a bundled markdown document, offline.
class LegalScreen extends StatelessWidget {
  const LegalScreen({super.key, required this.doc});

  final LegalDoc doc;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(children: [
          FolioHeader(leading: 'Privacy', center: doc.title),
          Expanded(
            child: FutureBuilder<String>(
              future: rootBundle.loadString(doc.asset),
              builder: (context, snap) => snap.hasData
                  ? SelectionArea(
                      child: ListView(
                        padding: const EdgeInsets.fromLTRB(folioMargin, 20, folioMargin, 40),
                        children: FolioMarkdown.render(context, snap.data!),
                      ),
                    )
                  : const SizedBox(),
            ),
          ),
        ]),
      ),
    );
  }
}

/// A small markdown renderer for the legal documents: headings, paragraphs,
/// bullet lists, **bold**, and simple tables. Enough for our own files.
abstract final class FolioMarkdown {
  static List<Widget> render(BuildContext context, String source) {
    final p = context.palette;
    final out = <Widget>[];
    final lines = source.replaceAll('\r', '').split('\n');
    var paragraph = <String>[];

    void flush() {
      if (paragraph.isEmpty) return;
      out.add(Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Text.rich(_inline(paragraph.join(' ').replaceAll('  ', ' '), FolioType.body(p, size: 16.5))),
      ));
      paragraph = [];
    }

    for (var i = 0; i < lines.length; i++) {
      final line = lines[i].trimRight();
      if (line.trim().isEmpty) {
        flush();
      } else if (line.startsWith('# ')) {
        flush();
        out.add(Padding(
          padding: const EdgeInsets.only(bottom: 14),
          child: Text(line.substring(2), style: FolioType.plateTitle(p, size: 30)),
        ));
      } else if (line.startsWith('## ')) {
        flush();
        out.add(Padding(
          padding: const EdgeInsets.only(top: 18, bottom: 8),
          child: Text(line.substring(3).toUpperCase(), style: FolioType.kicker(p)),
        ));
      } else if (line.startsWith('### ')) {
        flush();
        out.add(Padding(
          padding: const EdgeInsets.only(top: 10, bottom: 6),
          child: Text(line.substring(4), style: FolioType.body(p, size: 18).copyWith(fontWeight: FontWeight.w600)),
        ));
      } else if (line.trimLeft().startsWith('- ')) {
        flush();
        out.add(Padding(
          padding: const EdgeInsets.only(bottom: 8, left: 4),
          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Padding(
              padding: const EdgeInsets.only(top: 8, right: 10),
              child: Container(width: 5, height: 5, color: p.textMuted),
            ),
            Expanded(child: Text.rich(_inline(line.trimLeft().substring(2), FolioType.body(p, size: 16.5)))),
          ]),
        ));
      } else if (line.startsWith('|')) {
        flush();
        final rows = <List<String>>[];
        while (i < lines.length && lines[i].trim().startsWith('|')) {
          final cells = lines[i].trim().split('|').map((c) => c.trim()).toList()
            ..removeAt(0)
            ..removeLast();
          if (!cells.every((c) => RegExp(r'^:?-+:?$').hasMatch(c))) rows.add(cells);
          i++;
        }
        i--;
        out.add(Padding(
          padding: const EdgeInsets.only(bottom: 14),
          child: Column(children: [
            for (var r = 0; r < rows.length; r++)
              Container(
                decoration: BoxDecoration(border: Border(bottom: BorderSide(color: p.rule))),
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  for (var c = 0; c < rows[r].length; c++)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 2),
                      child: Text.rich(_inline(
                        rows[r][c],
                        r == 0 || c == 0
                            ? FolioType.body(p, size: 15.5).copyWith(fontWeight: FontWeight.w600)
                            : FolioType.body(p, size: 15.5).copyWith(color: p.textMuted),
                      )),
                    ),
                ]),
              ),
          ]),
        ));
      } else {
        paragraph.add(line.trim());
      }
    }
    flush();
    return out;
  }

  /// `**bold**`, `*italic*` and `code` spans.
  static TextSpan _inline(String text, TextStyle base) {
    final spans = <TextSpan>[];
    final re = RegExp(r'\*\*(.+?)\*\*|\*(.+?)\*|`(.+?)`');
    var last = 0;
    for (final m in re.allMatches(text)) {
      if (m.start > last) spans.add(TextSpan(text: text.substring(last, m.start)));
      if (m.group(1) != null) {
        spans.add(TextSpan(text: m.group(1), style: const TextStyle(fontWeight: FontWeight.w600)));
      } else if (m.group(2) != null) {
        spans.add(TextSpan(text: m.group(2), style: const TextStyle(fontStyle: FontStyle.italic)));
      } else {
        spans.add(TextSpan(text: m.group(3)));
      }
      last = m.end;
    }
    if (last < text.length) spans.add(TextSpan(text: text.substring(last)));
    return TextSpan(style: base, children: spans);
  }
}
