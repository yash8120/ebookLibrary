import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/ebook.dart';
import '../state/library_state.dart';
import '../widgets/bookshelf.dart';
import '../widgets/state_views.dart';
import 'reader_screen.dart';
import 'upload_screen.dart';

class LibraryScreen extends StatefulWidget {
  const LibraryScreen({super.key});

  @override
  State<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends State<LibraryScreen> {
  final _searchController = TextEditingController();
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    // Loading the shelf as soon as the screen mounts, rather than
    // waiting on a manual refresh, keeps the first-run experience
    // from feeling broken.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<LibraryState>().loadEbooks();
    });
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 350), () {
      context.read<LibraryState>().search(value);
    });
  }

  Future<void> _confirmDelete(Ebook ebook) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete this ebook?'),
        content: Text('"${ebook.title}" will be permanently removed.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    final success = await context.read<LibraryState>().delete(ebook);
    if (!mounted) return;
    if (!success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not delete the ebook. Please try again.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<LibraryState>();

    return Scaffold(
      backgroundColor: const Color(0xFFF4ECE0),
      appBar: AppBar(
        title: const Text('My Library'),
        backgroundColor: const Color(0xFF3E2723),
        foregroundColor: Colors.white,
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final uploaded = await Navigator.push<bool>(
            context,
            MaterialPageRoute(builder: (_) => const UploadScreen()),
          );
          if (uploaded == true && mounted) {
            context.read<LibraryState>().loadEbooks();
          }
        },
        icon: const Icon(Icons.add),
        label: const Text('Add ebook'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: TextField(
              controller: _searchController,
              onChanged: _onSearchChanged,
              decoration: InputDecoration(
                hintText: 'Search by title, author, or file name',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          context.read<LibraryState>().search('');
                        },
                      )
                    : null,
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
          Expanded(child: _buildBody(context, state)),
        ],
      ),
    );
  }

  Widget _buildBody(BuildContext context, LibraryState state) {
    switch (state.status) {
      case LoadStatus.initial:
      case LoadStatus.loading:
        return const LoadingView();
      case LoadStatus.error:
        return ErrorView(
          message: state.errorMessage ?? 'Something went wrong.',
          onRetry: () => context.read<LibraryState>().loadEbooks(),
        );
      case LoadStatus.loaded:
        if (state.ebooks.isEmpty) {
          if (state.query.isNotEmpty) {
            return NoSearchResultsView(query: state.query);
          }
          return EmptyLibraryView(
            onUpload: () async {
              final uploaded = await Navigator.push<bool>(
                context,
                MaterialPageRoute(builder: (_) => const UploadScreen()),
              );
              if (uploaded == true && mounted) {
                context.read<LibraryState>().loadEbooks();
              }
            },
          );
        }
        return RefreshIndicator(
          onRefresh: () => context.read<LibraryState>().loadEbooks(),
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.only(top: 16, bottom: 96),
            child: Bookshelf(
              ebooks: state.ebooks,
              onOpen: (ebook) => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => ReaderScreen(ebook: ebook)),
              ),
              onDelete: _confirmDelete,
            ),
          ),
        );
    }
  }
}
