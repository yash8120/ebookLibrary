import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_pdfview/flutter_pdfview.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';

import '../models/ebook.dart';
import '../services/api_service.dart';
import '../state/library_state.dart';

/// Opens a single ebook for reading. PDFs are rendered in-app; EPUB
/// support is a documented limitation for this milestone (see
/// README) — those files can still be downloaded and opened in an
/// external reader.
class ReaderScreen extends StatefulWidget {
  const ReaderScreen({super.key, required this.ebook});

  final Ebook ebook;

  @override
  State<ReaderScreen> createState() => _ReaderScreenState();
}

class _ReaderScreenState extends State<ReaderScreen> {
  String? _localPath;
  bool _loading = true;
  String? _error;
  int _currentPage = 0;
  int _totalPages = 0;

  @override
  void initState() {
    super.initState();
    if (widget.ebook.isPdf) {
      _prepareFile();
    } else {
      _loading = false;
    }
  }

  Future<void> _prepareFile() async {
    try {
      final api = ApiService();
      final bytes = await api.downloadEbook(widget.ebook);
      final dir = await getTemporaryDirectory();
      final file = File('${dir.path}/ebook_${widget.ebook.id}.pdf');
      await file.writeAsBytes(bytes, flush: true);
      if (!mounted) return;
      setState(() {
        _localPath = file.path;
        _loading = false;
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.message;
        _loading = false;
      });
    }
  }

  Future<void> _downloadToDevice() async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      final api = ApiService();
      final bytes = await api.downloadEbook(widget.ebook);
      final dir = await getApplicationDocumentsDirectory();
      final fileName = '${widget.ebook.title}.${widget.ebook.isEpub ? 'epub' : 'pdf'}';
      final file = File('${dir.path}/$fileName');
      await file.writeAsBytes(bytes, flush: true);
      messenger.showSnackBar(SnackBar(content: Text('Saved to ${file.path}')));
    } on ApiException catch (e) {
      messenger.showSnackBar(SnackBar(content: Text(e.message)));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: Text(widget.ebook.title, overflow: TextOverflow.ellipsis),
        actions: [
          IconButton(
            icon: const Icon(Icons.download),
            tooltip: 'Download',
            onPressed: _downloadToDevice,
          ),
        ],
      ),
      body: _buildBody(),
      bottomNavigationBar: (widget.ebook.isPdf && _totalPages > 0)
          ? Container(
              color: Colors.black87,
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Text(
                'Page ${_currentPage + 1} of $_totalPages',
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white70),
              ),
            )
          : null,
    );
  }

  Widget _buildBody() {
    if (!widget.ebook.isPdf) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.menu_book, color: Colors.white54, size: 48),
              const SizedBox(height: 12),
              const Text(
                'In-app reading currently supports PDF only.',
                style: TextStyle(color: Colors.white70),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: _downloadToDevice,
                icon: const Icon(Icons.download),
                label: const Text('Download to read externally'),
              ),
            ],
          ),
        ),
      );
    }

    if (_loading) {
      return const Center(child: CircularProgressIndicator(color: Colors.white));
    }

    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, color: Colors.redAccent, size: 40),
              const SizedBox(height: 12),
              Text(_error!, style: const TextStyle(color: Colors.white70)),
              const SizedBox(height: 16),
              OutlinedButton(
                onPressed: () {
                  setState(() {
                    _loading = true;
                    _error = null;
                  });
                  _prepareFile();
                },
                child: const Text('Try again'),
              ),
            ],
          ),
        ),
      );
    }

    return PDFView(
      filePath: _localPath!,
      enableSwipe: true,
      swipeHorizontal: false,
      autoSpacing: true,
      pageFling: true,
      onRender: (pages) => setState(() => _totalPages = pages ?? 0),
      onPageChanged: (page, total) => setState(() {
        _currentPage = page ?? 0;
        _totalPages = total ?? _totalPages;
      }),
    );
  }
}
