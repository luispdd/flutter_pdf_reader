import 'package:flutter/material.dart';
import 'package:flutter_pdf_reader/core/app_theme.dart';
import 'package:flutter_pdf_reader/widgets/secondary_button.dart';
import 'package:flutter_pdf_reader/widgets/waveform_bars.dart';

import 'package:flutter_pdf_reader/controllers/document_reader_controller.dart';

class ClipboardReaderScreen extends StatelessWidget {
  final DocumentReaderController controller;

  const ClipboardReaderScreen({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBgDark,
      appBar: AppBar(
        title: const Text('Clipboard Reader'),
        automaticallyImplyLeading: false,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 40),
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
                    Icons.content_paste,
                    size: 36,
                    color: Colors.white,
                  ),
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'Reading from clipboard',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w500,
                  color: kTextPrimary,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Your clipboard content is being narrated.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.white.withValues(alpha: 0.40),
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 32),
              WaveformBars(isPlaying: controller.isReadingClipboard),
              const SizedBox(height: 24),
              Center(
                child: GestureDetector(
                  onTap: () => controller.stopClipboardNarration(),
                  child: Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [kAmber, kAmberDark],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: kAmber.withValues(alpha: 0.25),
                          blurRadius: 20,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.stop_rounded,
                      size: 28,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
              const Spacer(),
              SecondaryButton(
                onPressed: () => controller.stopClipboardNarration(),
                icon: Icons.arrow_back,
                label: 'Back to home',
              ),
            ],
          ),
        ),
      ),
    );
  }
}
