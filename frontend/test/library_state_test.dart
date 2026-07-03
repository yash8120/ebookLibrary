import 'package:flutter_test/flutter_test.dart';

import 'package:ebook_library/models/ebook.dart';
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

void main() {
  group('LibraryState', () {
    test('loadEbooks populates the list and sets status to loaded', () async {
      final fake = FakeApiService(initialEbooks: [_ebook(1, 'Dune')]);
      final state = LibraryState(apiService: fake);

      await state.loadEbooks();

      expect(state.status, LoadStatus.loaded);
      expect(state.ebooks, hasLength(1));
      expect(state.isEmpty, isFalse);
    });

    test('loadEbooks with no ebooks results in isEmpty true', () async {
      final fake = FakeApiService(initialEbooks: []);
      final state = LibraryState(apiService: fake);

      await state.loadEbooks();

      expect(state.status, LoadStatus.loaded);
      expect(state.isEmpty, isTrue);
    });

    test('loadEbooks surfaces an error message on failure', () async {
      final fake = FakeApiService()..shouldFail = true;
      final state = LibraryState(apiService: fake);

      await state.loadEbooks();

      expect(state.status, LoadStatus.error);
      expect(state.errorMessage, isNotNull);
    });

    test('search filters results by title', () async {
      final fake = FakeApiService(initialEbooks: [
        _ebook(1, 'Ruby Basics'),
        _ebook(2, 'Advanced Flutter'),
      ]);
      final state = LibraryState(apiService: fake);

      await state.search('ruby');

      expect(state.ebooks, hasLength(1));
      expect(state.ebooks.first.title, 'Ruby Basics');
    });

    test('an empty search query reloads the full list', () async {
      final fake = FakeApiService(initialEbooks: [_ebook(1, 'Book A'), _ebook(2, 'Book B')]);
      final state = LibraryState(apiService: fake);

      await state.search('');

      expect(state.ebooks, hasLength(2));
    });

    test('delete removes the ebook optimistically and confirms via the API', () async {
      final target = _ebook(1, 'To Delete');
      final fake = FakeApiService(initialEbooks: [target]);
      final state = LibraryState(apiService: fake);
      await state.loadEbooks();

      final result = await state.delete(target);

      expect(result, isTrue);
      expect(state.ebooks, isEmpty);
    });

    test('delete rolls back the optimistic removal if the API call fails', () async {
      final target = _ebook(1, 'Stubborn Book');
      final fake = FakeApiService(initialEbooks: [target]);
      final state = LibraryState(apiService: fake);
      await state.loadEbooks();

      fake.shouldFail = true;
      final result = await state.delete(target);

      expect(result, isFalse);
      expect(state.ebooks, contains(target));
    });
  });
}
