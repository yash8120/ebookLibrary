import 'dart:typed_data';

import 'package:ebook_library/models/ebook.dart';
import 'package:ebook_library/services/api_service.dart';

/// In-memory stand-in for [ApiService] so widget/state tests don't
/// need a running Rails server. Override the `*Result` fields per
/// test to simulate success, empty results, or failure.
class FakeApiService extends ApiService {
  FakeApiService({List<Ebook>? initialEbooks})
      : ebooks = initialEbooks ?? [];

  List<Ebook> ebooks;
  bool shouldFail = false;
  String failureMessage = 'Could not reach the server. Is it running?';

  @override
  Future<List<Ebook>> fetchEbooks() async {
    if (shouldFail) throw ApiException(failureMessage);
    return ebooks;
  }

  @override
  Future<List<Ebook>> searchEbooks(String query) async {
    if (shouldFail) throw ApiException(failureMessage);
    return ebooks
        .where((e) =>
            e.title.toLowerCase().contains(query.toLowerCase()) ||
            (e.author ?? '').toLowerCase().contains(query.toLowerCase()))
        .toList();
  }

  @override
  Future<Ebook> uploadEbook({
    required String filePath,
    required String title,
    String? author,
    String? coverPath,
  }) async {
    if (shouldFail) throw ApiException(failureMessage);
    final ebook = Ebook(
      id: ebooks.length + 1,
      title: title,
      author: author,
      fileType: 'application/pdf',
      fileSize: 1024,
      uploadedAt: DateTime.now(),
    );
    ebooks = [ebook, ...ebooks];
    return ebook;
  }

  @override
  Future<void> deleteEbook(int id) async {
    if (shouldFail) throw ApiException(failureMessage);
    ebooks = ebooks.where((e) => e.id != id).toList();
  }

  @override
  Future<Uint8List> downloadEbook(Ebook ebook) async {
    if (shouldFail) throw ApiException(failureMessage);
    return Uint8List(0);
  }
}
