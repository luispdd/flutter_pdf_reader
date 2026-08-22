import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:flutter_pdf_reader/core/app_theme.dart';
import 'package:flutter_pdf_reader/screens/empty_state_view.dart';
import 'package:flutter_pdf_reader/screens/player_view.dart';
import 'package:flutter_pdf_reader/screens/clipboard_reader_screen.dart';
import 'package:flutter_pdf_reader/screens/configuration_screen.dart';

import 'package:flutter_pdf_reader/controllers/document_reader_controller.dart';

class DocumentReaderScreen extends StatelessWidget {
  const DocumentReaderScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<DocumentReaderController>();

    // Clipboard takes over the whole screen when active
    if (controller.isReadingClipboard) {
      return ClipboardReaderScreen(controller: controller);
    }

    return Scaffold(
      backgroundColor: kBgDark,
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Document Audio Reader'),
            if (controller.documentFileName != null)
              Text(
                controller.documentFileName!,
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.white.withValues(alpha: 0.35),
                  fontWeight: FontWeight.normal,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            tooltip: 'Configuration',
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => const ConfigurationScreen(),
                ),
              );
            },
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: controller.totalChunks == 0 && !controller.isLoading
              ? EmptyStateView(
                  onPickFile: () => controller.pickFile(),
                  onReadClipboard: () => controller.readClipboard(),
                )
              : PlayerView(controller: controller),
        ),
      ),
    );
  }
}
