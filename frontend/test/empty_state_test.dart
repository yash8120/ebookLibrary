import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:ebook_library/widgets/state_views.dart';

void main() {
  testWidgets('EmptyLibraryView shows prompt and upload button', (tester) async {
    var tapped = false;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: EmptyLibraryView(onUpload: () => tapped = true),
        ),
      ),
    );

    expect(find.text('Your shelf is empty'), findsOneWidget);
    expect(find.text('Upload an ebook'), findsOneWidget);

    await tester.tap(find.text('Upload an ebook'));
    await tester.pump();

    expect(tapped, isTrue);
  });

  testWidgets('NoSearchResultsView shows the query that had no matches', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(body: NoSearchResultsView(query: 'atlantis')),
      ),
    );

    expect(find.text('No results for "atlantis"'), findsOneWidget);
  });
}
