/// Represents a single ebook as returned by the Rails API.
class Ebook {
  final int id;
  final String title;
  final String? author;
  final String? fileType;
  final int? fileSize;
  final DateTime uploadedAt;
  final String? coverUrl;
  final String? downloadUrl;

  Ebook({
    required this.id,
    required this.title,
    this.author,
    this.fileType,
    this.fileSize,
    required this.uploadedAt,
    this.coverUrl,
    this.downloadUrl,
  });

  factory Ebook.fromJson(Map<String, dynamic> json) {
    return Ebook(
      id: json['id'] as int,
      title: json['title'] as String? ?? 'Untitled',
      author: json['author'] as String?,
      fileType: json['file_type'] as String?,
      fileSize: json['file_size'] as int?,
      uploadedAt: DateTime.tryParse(json['uploaded_at'] as String? ?? '') ??
          DateTime.now(),
      coverUrl: json['cover_url'] as String?,
      downloadUrl: json['download_url'] as String?,
    );
  }

  /// True for EPUB files, so the UI can badge/handle them differently
  /// from PDFs (which are the only format we currently render in-app).
  bool get isEpub => fileType?.contains('epub') ?? false;

  bool get isPdf => fileType?.contains('pdf') ?? false;

  String get formattedSize {
    if (fileSize == null) return '';
    final kb = fileSize! / 1024;
    if (kb < 1024) return '${kb.toStringAsFixed(0)} KB';
    return '${(kb / 1024).toStringAsFixed(1)} MB';
  }
}
