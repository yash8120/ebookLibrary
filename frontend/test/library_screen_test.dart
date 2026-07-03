import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:ebook_library/models/ebook.dart';
import 'package:ebook_library/screens/library_screen.dart';
import 'package:ebook_library/state/library_state.dart';

import 'fakes/fake_api_service.dart';

Ebook _ebook(int id, String title, {String? author}) => Ebook(
      id: id,
      title: title,
      author: author,
      fileType: 'application/pdf',
      fileSize: 1024,
      uploadedAt: DateTime(2026, 1, 1),
    );

Widget _wrap(LibraryState state) {
  return ChangeNotifierProvider.value(
    value: state,
    child: const MaterialApp(home: LibraryScreen()),
  );
}

void main() {
  testWidgets('shows the empty state when the library has no ebooks', (tester) async {
    final fake = FakeApiService(initialEbooks: []);
    final state = LibraryState(apiService: fake);

    await tester.pumpWidget(_wrap(state));
    await tester.pumpAndSettle();

    expect(find.text('Your shelf is empty'), findsOneWidget);
  });

  testWidgets('renders an ebook card for each uploaded book', (tester) async {
    final fake = FakeApiService(initialEbooks: [
      _ebook(1, 'Clean Code', author: 'Robert Martin'),
      _ebook(2, 'The Pragmatic Programmer', author: 'Andy Hunt'),
    ]);
    final state = LibraryState(apiService: fake);

    await tester.pumpWidget(_wrap(state));
    await tester.pumpAndSettle();

    expect(find.text('Clean Code'), findsOneWidget);
    expect(find.text('The Pragmatic Programmer'), findsOneWidget);
  });

  testWidgets('typing in the search box filters the shelf', (tester) async {
    final fake = FakeApiService(initialEbooks: [
      _ebook(1, 'Clean Code'),
      _ebook(2, 'Flutter in Action'),
    ]);
    final state = LibraryState(apiService: fake);

    await tester.pumpWidget(_wrap(state));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField), 'flutter');
    // Search is debounced by 350ms.
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pumpAndSettle();

    expect(find.text('Flutter in Action'), findsOneWidget);
    expect(find.text('Clean Code'), findsNothing);
  });

  testWidgets('search with no matches shows the no-results state', (tester) async {
    final fake = FakeApiService(initialEbooks: [_ebook(1, 'Clean Code')]);
    final state = LibraryState(apiService: fake);

    await tester.pumpWidget(_wrap(state));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField), 'nonexistent');
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pumpAndSettle();

    expect(find.textContaining('No results for'), findsOneWidget);
  });

  testWidgets('long-pressing a book asks for delete confirmation before removing it',
      (tester) async {
    final fake = FakeApiService(initialEbooks: [_ebook(1, 'Clean Code')]);
    final state = LibraryState(apiService: fake);

    await tester.pumpWidget(_wrap(state));
    await tester.pumpAndSettle();

    await tester.longPress(find.text('Clean Code'));
    await tester.pumpAndSettle();

    expect(find.text('Delete this ebook?'), findsOneWidget);

    await tester.tap(find.text('Delete'));
    await tester.pumpAndSettle();

    expect(find.text('Clean Code'), findsNothing);
    expect(find.text('Your shelf is empty'), findsOneWidget);
  });

  testWidgets('canceling the delete dialog keeps the book on the shelf', (tester) async {
    final fake = FakeApiService(initialEbooks: [_ebook(1, 'Clean Code')]);
    final state = LibraryState(apiService: fake);

    await tester.pumpWidget(_wrap(state));
    await tester.pumpAndSettle();

    await tester.longPress(find.text('Clean Code'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();

    expect(find.text('Clean Code'), findsOneWidget);
  });
}
