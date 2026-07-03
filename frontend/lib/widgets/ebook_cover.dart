import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../models/ebook.dart';

/// Renders a single book on the shelf: a cover image if one was
/// uploaded, otherwise a generated "spine" using the title's first
/// letter and a color derived from the title, so an empty-cover
/// library still looks intentional rather than broken.
class EbookCover extends StatelessWidget {
  const EbookCover({
    super.key,
    required this.ebook,
    required this.onTap,
    required this.onLongPress,
  });

  final Ebook ebook;
  final VoidCallback onTap;
  final VoidCallback onLongPress;

  Color _spineColor(String title) {
    const palette = [
      Color(0xFF6D4C41),
      Color(0xFF8D6E63),
      Color(0xFF5D4037),
      Color(0xFF4E342E),
      Color(0xFF3E2723),
      Color(0xFF795548),
    ];
    final hash = title.codeUnits.fold<int>(0, (a, b) => a + b);
    return palette[hash % palette.length];
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      onLongPress: onLongPress,
      child: Semantics(
        label: '${ebook.title}${ebook.author != null ? ' by ${ebook.author}' : ''}',
        button: true,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(4),
            boxShadow: const [
              BoxShadow(color: Colors.black38, blurRadius: 4, offset: Offset(1, 3)),
            ],
          ),
          clipBehavior: Clip.antiAlias,
          child: ebook.coverUrl != null
              ? CachedNetworkImage(
                  imageUrl: ebook.coverUrl!,
                  fit: BoxFit.cover,
                  errorWidget: (_, __, ___) => _placeholderSpine(context),
                  placeholder: (_, __) => _placeholderSpine(context),
                )
              : _placeholderSpine(context),
        ),
      ),
    );
  }

  Widget _placeholderSpine(BuildContext context) {
    return Container(
      color: _spineColor(ebook.title),
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 10),
      alignment: Alignment.center,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            ebook.title,
            maxLines: 4,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w600,
              fontSize: 12,
              height: 1.2,
            ),
          ),
          if (ebook.isEpub) ...[
            const SizedBox(height: 6),
            const Text('EPUB',
                style: TextStyle(color: Colors.white70, fontSize: 9, letterSpacing: 1)),
          ],
        ],
      ),
    );
  }
}
