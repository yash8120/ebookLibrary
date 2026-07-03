import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:http/http.dart' as http;

import '../models/ebook.dart';

/// Thrown for any failure talking to the backend so screens can show
/// a single, consistent error state.
class ApiException implements Exception {
  final String message;
  ApiException(this.message);

  @override
  String toString() => message;
}

/// Thin wrapper around the Rails JSON API described in the README.
///
/// Uses `http` for simple JSON calls and `dio` for multipart upload /
/// binary download, where its progress callbacks are convenient.
class ApiService {
  ApiService({String? baseUrl})
      : baseUrl = baseUrl ??
            // 10.0.2.2 is how the Android emulator reaches the host
            // machine's localhost. Override via --dart-define for iOS
            // simulator / physical devices / production builds.
            const String.fromEnvironment(
              'API_BASE_URL',
              defaultValue: 'http://10.0.2.2:3000',
            );

  final String baseUrl;
  final Dio _dio = Dio();

  Uri _uri(String path) => Uri.parse('$baseUrl$path');

  Future<List<Ebook>> fetchEbooks() async {
    try {
      final res = await http.get(_uri('/api/ebooks'));
      _ensureOk(res);
      final List<dynamic> data = jsonDecode(res.body) as List<dynamic>;
      return data
          .map((e) => Ebook.fromJson(e as Map<String, dynamic>))
          .toList();
    } on SocketException {
      throw ApiException('Could not reach the server. Is it running?');
    }
  }

  Future<List<Ebook>> searchEbooks(String query) async {
    try {
      final res = await http
          .get(_uri('/api/ebooks/search').replace(queryParameters: {'q': query}));
      _ensureOk(res);
      final List<dynamic> data = jsonDecode(res.body) as List<dynamic>;
      return data
          .map((e) => Ebook.fromJson(e as Map<String, dynamic>))
          .toList();
    } on SocketException {
      throw ApiException('Could not reach the server. Is it running?');
    }
  }

  Future<Ebook> uploadEbook({
    required String filePath,
    required String title,
    String? author,
    String? coverPath,
  }) async {
    try {
      final formData = FormData.fromMap({
        'title': title,
        if (author != null && author.isNotEmpty) 'author': author,
        'file': await MultipartFile.fromFile(filePath),
        if (coverPath != null)
          'cover': await MultipartFile.fromFile(coverPath),
      });

      final response = await _dio.post('$baseUrl/api/ebooks', data: formData);

      if (response.statusCode == 201) {
        return Ebook.fromJson(response.data as Map<String, dynamic>);
      }

      throw ApiException(_extractDioError(response.data));
    } on DioException catch (e) {
      if (e.response != null) {
        throw ApiException(_extractDioError(e.response!.data));
      }
      throw ApiException('Upload failed. Check your connection and try again.');
    }
  }

  Future<void> deleteEbook(int id) async {
    try {
      final res = await http.delete(_uri('/api/ebooks/$id'));
      if (res.statusCode != 204) {
        throw ApiException('Could not delete this ebook (${res.statusCode}).');
      }
    } on SocketException {
      throw ApiException('Could not reach the server. Is it running?');
    }
  }

  /// Downloads the ebook's raw bytes, for saving to local storage or
  /// handing off to the platform's "share/save" sheet.
  Future<Uint8List> downloadEbook(Ebook ebook) async {
    try {
      final response = await _dio.get<List<int>>(
        '$baseUrl/api/ebooks/${ebook.id}/download',
        options: Options(responseType: ResponseType.bytes),
      );
      return Uint8List.fromList(response.data ?? const []);
    } on DioException {
      throw ApiException('Download failed. Please try again.');
    }
  }

  void _ensureOk(http.Response res) {
    if (res.statusCode != 200) {
      throw ApiException('Request failed (${res.statusCode}).');
    }
  }

  String _extractDioError(dynamic data) {
    if (data is Map && data['errors'] is List) {
      return (data['errors'] as List).join(', ');
    }
    return 'Something went wrong. Please try again.';
  }
}
