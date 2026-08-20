import 'package:flutter/material.dart';
import 'package:flutter_pdf_reader/core/app_theme.dart';

class TextReaderScreen extends StatelessWidget {
  final String title;
  final String text;

  const TextReaderScreen({super.key, required this.title, required this.text});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBgDark,
      appBar: AppBar(
        title: Text(title),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Text(
            text,
            style: TextStyle(
              fontSize: 15,
              color: Colors.white.withValues(alpha: 0.75),
              height: 1.7,
            ),
          ),
        ),
      ),
    );
  }
}
