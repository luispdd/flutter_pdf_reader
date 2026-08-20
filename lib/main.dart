import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:flutter_pdf_reader/core/app_theme.dart';
import 'package:flutter_pdf_reader/screens/document_reader_screen.dart';
import 'package:flutter_pdf_reader/controllers/document_reader_controller.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => DocumentReaderController(),
      child: MaterialApp(
        title: 'Document Reader',
        debugShowCheckedModeBanner: false,
        themeMode: ThemeMode.dark,
        theme: buildAppTheme(),
        home: const DocumentReaderScreen(),
      ),
    );
  }
}
