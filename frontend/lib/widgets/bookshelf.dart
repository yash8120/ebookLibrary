import 'package:flutter/material.dart';

import '../models/ebook.dart';
import 'ebook_cover.dart';

/// Lays out ebooks in rows separated by a wooden shelf strip,
/// evoking the classic iOS ebook-library look. Each row holds as
/// many covers as fit at [coverWidth], wrapping to a new shelf.
class Bookshelf extends StatelessWidget {
  const Bookshelf({
    super.key,
    required this.ebooks,
    required this.onOpen,
    required this.onDelete,
  });

  final List<Ebook> ebooks;
  final ValueChanged<Ebook> onOpen;
  final ValueChanged<Ebook> onDelete;

  static const double coverWidth = 100;
  static const double coverHeight = 150;
  static const double spacing = 16;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final perRow =
            ((constraints.maxWidth + spacing) / (coverWidth + spacing)).floor().clamp(1, 100);
        final rows = <List<Ebook>>[];
        for (var i = 0; i < ebooks.length; i += perRow) {
          rows.add(ebooks.sublist(i, (i + perRow).clamp(0, ebooks.length)));
        }

        return Column(
          children: [
            for (final row in rows) _ShelfRow(row: row, onOpen: onOpen, onDelete: onDelete),
          ],
        );
      },
    );
  }
}

class _ShelfRow extends StatelessWidget {
  const _ShelfRow({required this.row, required this.onOpen, required this.onDelete});

  final List<Ebook> row;
  final ValueChanged<Ebook> onOpen;
  final ValueChanged<Ebook> onDelete;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Column(
        children: [
          SizedBox(
            height: Bookshelf.coverHeight,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                for (final ebook in row)
                  Padding(
                    padding: const EdgeInsets.only(right: Bookshelf.spacing),
                    child: SizedBox(
                      width: Bookshelf.coverWidth,
                      height: Bookshelf.coverHeight,
                      child: EbookCover(
                        ebook: ebook,
                        onTap: () => onOpen(ebook),
                        onLongPress: () => onDelete(ebook),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          // The wooden shelf plank underneath each row of books.
          Container(
            height: 14,
            margin: const EdgeInsets.only(bottom: 24),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF8B5E34), Color(0xFF6B4423)],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
              borderRadius: BorderRadius.circular(2),
              boxShadow: const [
                BoxShadow(color: Colors.black45, blurRadius: 6, offset: Offset(0, 4)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
