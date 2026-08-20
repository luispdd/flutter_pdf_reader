import 'package:flutter/material.dart';
import 'package:flutter_pdf_reader/core/app_theme.dart';
import 'package:flutter_pdf_reader/widgets/gradient_button.dart';
import 'package:flutter_pdf_reader/widgets/secondary_button.dart';

class EmptyStateView extends StatelessWidget {
  final VoidCallback onPickFile;
  final VoidCallback onReadClipboard;

  const EmptyStateView({
    super.key,
    required this.onPickFile,
    required this.onReadClipboard,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Spacer(flex: 2),
        Center(
          child: Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [kAmber, kAmberDark],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: kAmber.withValues(alpha: 0.20),
                  blurRadius: 24,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: const Icon(
              Icons.menu_book_rounded,
              size: 36,
              color: Colors.white,
            ),
          ),
        ),
        const SizedBox(height: 24),
        const Text(
          'No document selected',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w500,
            color: kTextPrimary,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Upload a PDF or EPUB file, or paste text from your clipboard to start listening.',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 14,
            color: Colors.white.withValues(alpha: 0.40),
            height: 1.5,
          ),
        ),
        const SizedBox(height: 32),
        GradientButton(
          onPressed: onPickFile,
          icon: Icons.file_upload,
          label: 'Select PDF or EPUB file',
        ),
        const SizedBox(height: 12),
        SecondaryButton(
          onPressed: onReadClipboard,
          icon: Icons.content_paste,
          label: 'Read text from clipboard',
        ),
        const Spacer(flex: 3),
      ],
    );
  }
}
