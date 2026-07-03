import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'screens/library_screen.dart';
import 'state/library_state.dart';

void main() {
  runApp(const EbookLibraryApp());
}

class EbookLibraryApp extends StatelessWidget {
  const EbookLibraryApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => LibraryState(),
      child: MaterialApp(
        title: 'Ebook Library',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          useMaterial3: true,
          colorSchemeSeed: const Color(0xFF6D4C41),
          scaffoldBackgroundColor: const Color(0xFFF4ECE0),
        ),
        home: const LibraryScreen(),
      ),
    );
  }
}
