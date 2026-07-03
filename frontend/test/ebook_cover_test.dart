import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:ebook_library/models/ebook.dart';
import 'package:ebook_library/widgets/ebook_cover.dart';

Ebook _sampleEbook({String title = 'Test Driven Development', String? coverUrl}) {
  return Ebook(
    id: 1,
    title: title,
    author: 'Kent Beck',
    fileType: 'application/pdf',
    fileSize: 204800,
    uploadedAt: DateTime(2026, 1, 1),
    coverUrl: coverUrl,
  );
}

void main() {
  testWidgets('renders a placeholder spine with the title when no cover image is set',
      (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 100,
            height: 150,
            child: EbookCover(
              ebook: _sampleEbook(),
              onTap: () {},
              onLongPress: () {},
            ),
          ),
        ),
      ),
    );

    expect(find.text('Test Driven Development'), findsOneWidget);
  });

  testWidgets('tapping the cover triggers onTap', (tester) async {
    var tapped = false;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 100,
            height: 150,
            child: EbookCover(
              ebook: _sampleEbook(),
              onTap: () => tapped = true,
              onLongPress: () {},
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.byType(EbookCover));
    expect(tapped, isTrue);
  });

  testWidgets('long-pressing the cover triggers onLongPress (delete flow)', (tester) async {
    var longPressed = false;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 100,
            height: 150,
            child: EbookCover(
              ebook: _sampleEbook(),
              onTap: () {},
              onLongPress: () => longPressed = true,
            ),
          ),
        ),
      ),
    );

    await tester.longPress(find.byType(EbookCover));
    expect(longPressed, isTrue);
  });
}
