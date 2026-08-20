import 'package:flutter/material.dart';
import 'package:flutter_pdf_reader/core/app_theme.dart';
import 'package:flutter_pdf_reader/widgets/secondary_button.dart';
import 'package:flutter_pdf_reader/widgets/outline_button.dart';
import 'package:flutter_pdf_reader/widgets/waveform_bars.dart';
import 'package:flutter_pdf_reader/screens/text_reader_screen.dart';

import 'package:flutter_pdf_reader/controllers/document_reader_controller.dart';

class PlayerView extends StatelessWidget {
  final DocumentReaderController controller;

  const PlayerView({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    final chunkTypeLabel = controller.isEpub ? 'Chunk' : 'Page';

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (controller.isLoading && controller.totalChunks == 0)
            const SizedBox(
              height: 400,
              child: Center(child: CircularProgressIndicator(color: kAmber)),
            )
          else ...[
            // File chip
            if (controller.documentFileName != null)
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: kAmber.withValues(alpha: 0.10),
                  border: Border.all(color: kAmber.withValues(alpha: 0.18)),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.insert_drive_file_outlined,
                      size: 20,
                      color: kAmberLight,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        controller.documentFileName!,
                        style: TextStyle(fontSize: 13, color: kAmberLight),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 24),

            // Page / Chunk selector
            if (controller.totalChunks > 0) ...[
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    '$chunkTypeLabel ',
                    style: TextStyle(
                      fontSize: 15,
                      color: Colors.white.withValues(alpha: 0.40),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.05),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.10),
                      ),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<int>(
                        value: controller.currentChunk,
                        dropdownColor: kSurface,
                        menuMaxHeight: 300,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w500,
                          color: kTextPrimary,
                        ),
                        icon: Icon(
                          Icons.keyboard_arrow_down,
                          color: Colors.white.withValues(alpha: 0.40),
                        ),
                        items: List.generate(
                          controller.totalChunks,
                          (index) => DropdownMenuItem(
                            value: index + 1,
                            child: Text('${index + 1}'),
                          ),
                        ),
                        onChanged: (value) {
                          if (value != null) controller.setChunk(value);
                        },
                      ),
                    ),
                  ),
                  Text(
                    ' of ${controller.totalChunks}',
                    style: TextStyle(
                      fontSize: 15,
                      color: Colors.white.withValues(alpha: 0.40),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Slider
              Slider(
                value: controller.currentChunk.toDouble(),
                min: 1,
                max: controller.totalChunks.toDouble(),
                divisions: controller.totalChunks > 1
                    ? controller.totalChunks - 1
                    : 1,
                label: controller.currentChunk.toString(),
                onChanged: (value) => controller.setChunk(value.toInt()),
              ),
              const SizedBox(height: 8),

              // Waveform
              WaveformBars(isPlaying: controller.isPlaying),
              const SizedBox(height: 20),

              // Play / Stop button
              Center(
                child: GestureDetector(
                  onTap:
                      (controller.isLoading ||
                          controller.currentChunkText.isEmpty)
                      ? null
                      : () {
                          if (controller.isPlaying) {
                            controller.stopNarration();
                          } else {
                            controller.startNarration();
                          }
                        },
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
                    child: controller.isLoading
                        ? const Padding(
                            padding: EdgeInsets.all(16),
                            child: CircularProgressIndicator(
                              strokeWidth: 2.5,
                              valueColor: AlwaysStoppedAnimation(Colors.white),
                            ),
                          )
                        : Icon(
                            controller.isPlaying
                                ? Icons.stop_rounded
                                : Icons.play_arrow_rounded,
                            size: 28,
                            color: Colors.white,
                          ),
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Show text
              OutlineButton(
                onPressed: () =>
                    _pushTextView(context, controller, chunkTypeLabel),
                icon: Icons.text_snippet_outlined,
                label: 'Show $chunkTypeLabel text',
              ),
              const SizedBox(height: 12),
            ],

            // Upload another
            SecondaryButton(
              onPressed: () => controller.pickFile(),
              icon: Icons.file_upload,
              label: 'Select another file',
            ),
            const SizedBox(height: 12),

            // Clipboard
            SecondaryButton(
              onPressed: () {
                if (controller.isReadingClipboard) {
                  controller.stopClipboardNarration();
                } else {
                  controller.readClipboard();
                }
              },
              icon: controller.isReadingClipboard
                  ? Icons.stop
                  : Icons.content_paste,
              label: controller.isReadingClipboard
                  ? 'Stop clipboard playback'
                  : 'Read text from clipboard',
            ),
          ],
        ],
      ),
    );
  }

  void _pushTextView(
    BuildContext context,
    DocumentReaderController controller,
    String chunkTypeLabel,
  ) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => TextReaderScreen(
          title: '$chunkTypeLabel ${controller.currentChunk}',
          text: controller.currentChunkText.isEmpty
              ? "No text found on this $chunkTypeLabel."
              : controller.currentChunkText,
        ),
      ),
    );
  }
}
