import 'package:flutter/foundation.dart';

import '../models/ebook.dart';
import '../services/api_service.dart';

enum LoadStatus { initial, loading, loaded, error }

/// Central place holding the ebook list, the current search query, and
/// the loading/error state the UI reacts to. Kept intentionally small:
/// one list in memory, filtered client-side for a snappy search feel,
/// backed by a server-side search call for correctness on large
/// libraries.
class LibraryState extends ChangeNotifier {
  LibraryState({ApiService? apiService})
      : _api = apiService ?? ApiService();

  final ApiService _api;

  List<Ebook> _ebooks = [];
  LoadStatus _status = LoadStatus.initial;
  String? _errorMessage;
  String _query = '';

  List<Ebook> get ebooks => _ebooks;
  LoadStatus get status => _status;
  String? get errorMessage => _errorMessage;
  String get query => _query;
  bool get isEmpty => _status == LoadStatus.loaded && _ebooks.isEmpty;

  Future<void> loadEbooks() async {
    _status = LoadStatus.loading;
    notifyListeners();

    try {
      _ebooks = await _api.fetchEbooks();
      _status = LoadStatus.loaded;
    } on ApiException catch (e) {
      _errorMessage = e.message;
      _status = LoadStatus.error;
    }
    notifyListeners();
  }

  Future<void> search(String query) async {
    _query = query;
    if (query.trim().isEmpty) {
      return loadEbooks();
    }

    _status = LoadStatus.loading;
    notifyListeners();

    try {
      _ebooks = await _api.searchEbooks(query.trim());
      _status = LoadStatus.loaded;
    } on ApiException catch (e) {
      _errorMessage = e.message;
      _status = LoadStatus.error;
    }
    notifyListeners();
  }

  Future<bool> upload({
    required String filePath,
    required String title,
    String? author,
    String? coverPath,
  }) async {
    try {
      final ebook = await _api.uploadEbook(
        filePath: filePath,
        title: title,
        author: author,
        coverPath: coverPath,
      );
      _ebooks = [ebook, ..._ebooks];
      notifyListeners();
      return true;
    } on ApiException catch (e) {
      _errorMessage = e.message;
      notifyListeners();
      return false;
    }
  }

  Future<bool> delete(Ebook ebook) async {
    final previous = _ebooks;
    _ebooks = _ebooks.where((e) => e.id != ebook.id).toList();
    notifyListeners();

    try {
      await _api.deleteEbook(ebook.id);
      return true;
    } on ApiException catch (e) {
      // Roll back the optimistic removal so the shelf stays truthful.
      _ebooks = previous;
      _errorMessage = e.message;
      notifyListeners();
      return false;
    }
  }
}
