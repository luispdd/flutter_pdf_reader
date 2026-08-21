import 'package:flutter/material.dart';
import 'package:flutter_pdf_reader/core/app_theme.dart';
import 'package:flutter_pdf_reader/widgets/secondary_button.dart';
import 'package:flutter_pdf_reader/widgets/outline_button.dart';
import 'package:flutter_pdf_reader/widgets/waveform_bars.dart';

import 'package:flutter_pdf_reader/controllers/document_reader_controller.dart';

class PlayerView extends StatefulWidget {
  final DocumentReaderController controller;

  const PlayerView({super.key, required this.controller});

  @override
  State<PlayerView> createState() => _PlayerViewState();
}

class _PlayerViewState extends State<PlayerView> {
  bool _showingText = false;

  @override
  Widget build(BuildContext context) {
    final c = widget.controller;
    final chunkTypeLabel = c.isEpub ? 'Chunk' : 'Page';

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 250),
      transitionBuilder: (child, animation) => FadeTransition(
        opacity: animation,
        child: SizeTransition(
          sizeFactor: animation,
          alignment: Alignment.center,
          child: child,
        ),
      ),
      child: _showingText
          ? _buildReaderMode(context, c, chunkTypeLabel)
          : _buildPlayerMode(context, c, chunkTypeLabel),
    );
  }

  // ═══════════════════════════════════════════════════════════
  //  PLAYER MODE  (original layout)
  // ═══════════════════════════════════════════════════════════
  Widget _buildPlayerMode(
    BuildContext context,
    DocumentReaderController c,
    String chunkTypeLabel,
  ) {
    return SingleChildScrollView(
      key: const ValueKey('player'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (c.isLoading && c.totalChunks == 0)
            const SizedBox(
              height: 400,
              child: Center(child: CircularProgressIndicator(color: kAmber)),
            )
          else ...[
            // File chip
            if (c.documentFileName != null)
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
                        c.documentFileName!,
                        style: TextStyle(fontSize: 13, color: kAmberLight),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 24),

            // Page controls + play
            if (c.totalChunks > 0) ...[
              _pageControls(c, chunkTypeLabel),
              const SizedBox(height: 20),
              _playButton(c),
              const SizedBox(height: 24),
            ],

            // Toggle text
            OutlineButton(
              onPressed: () => setState(() => _showingText = true),
              icon: Icons.text_snippet_outlined,
              label: 'Show $chunkTypeLabel text',
            ),
            const SizedBox(height: 12),

            // Upload another
            SecondaryButton(
              onPressed: () => c.pickFile(),
              icon: Icons.file_upload,
              label: 'Select another file',
            ),
            const SizedBox(height: 12),

            // Clipboard
            SecondaryButton(
              onPressed: () {
                if (c.isReadingClipboard) {
                  c.stopClipboardNarration();
                } else {
                  c.readClipboard();
                }
              },
              icon: c.isReadingClipboard ? Icons.stop : Icons.content_paste,
              label: c.isReadingClipboard
                  ? 'Stop clipboard playback'
                  : 'Read text from clipboard',
            ),
          ],
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════
  //  READER MODE  (compact controls + scrollable text)
  // ═══════════════════════════════════════════════════════════
  Widget _buildReaderMode(
    BuildContext context,
    DocumentReaderController c,
    String chunkTypeLabel,
  ) {
    return Column(
      key: const ValueKey('reader'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Sticky top controls
        _pageControls(c, chunkTypeLabel),
        const SizedBox(height: 12),

        // Scrollable text
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.03),
              border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
              borderRadius: BorderRadius.circular(12),
            ),
            child: SingleChildScrollView(
              child: Text(
                c.currentChunkText.isEmpty
                    ? "No text found on this $chunkTypeLabel."
                    : c.currentChunkText,
                style: TextStyle(
                  fontSize: 15,
                  color: Colors.white.withValues(alpha: 0.75),
                  height: 1.7,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),

        // Playback controls at bottom
        _playButton(c),
        const SizedBox(height: 16),

        // Toggle back
        OutlineButton(
          onPressed: () => setState(() => _showingText = false),
          icon: Icons.keyboard_arrow_up,
          label: 'Hide $chunkTypeLabel text',
        ),
      ],
    );
  }

  // ═══════════════════════════════════════════════════════════
  //  SHARED: Page selector + slider
  // ═══════════════════════════════════════════════════════════
  Widget _pageControls(DocumentReaderController c, String chunkTypeLabel) {
    return Column(
      children: [
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
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.05),
                border: Border.all(color: Colors.white.withValues(alpha: 0.10)),
                borderRadius: BorderRadius.circular(8),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<int>(
                  value: c.currentChunk,
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
                    c.totalChunks,
                    (index) => DropdownMenuItem(
                      value: index + 1,
                      child: Text('${index + 1}'),
                    ),
                  ),
                  onChanged: (value) {
                    if (value != null) c.setChunk(value);
                  },
                ),
              ),
            ),
            Text(
              ' of ${c.totalChunks}',
              style: TextStyle(
                fontSize: 15,
                color: Colors.white.withValues(alpha: 0.40),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Slider(
          value: c.currentChunk.toDouble(),
          min: 1,
          max: c.totalChunks.toDouble(),
          divisions: c.totalChunks > 1 ? c.totalChunks - 1 : 1,
          label: c.currentChunk.toString(),
          onChanged: (value) => c.setChunk(value.toInt()),
        ),
      ],
    );
  }

  // ═══════════════════════════════════════════════════════════
  //  SHARED: Play button + waveform
  // ═══════════════════════════════════════════════════════════
  Widget _playButton(DocumentReaderController c) {
    return Column(
      children: [
        WaveformBars(isPlaying: c.isPlaying),
        const SizedBox(height: 16),
        Center(
          child: GestureDetector(
            onTap: (c.isLoading || c.currentChunkText.isEmpty)
                ? null
                : () {
                    if (c.isPlaying) {
                      c.stopNarration();
                    } else {
                      c.startNarration();
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
              child: c.isLoading
                  ? const Padding(
                      padding: EdgeInsets.all(16),
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        valueColor: AlwaysStoppedAnimation(Colors.white),
                      ),
                    )
                  : Icon(
                      c.isPlaying
                          ? Icons.stop_rounded
                          : Icons.play_arrow_rounded,
                      size: 28,
                      color: Colors.white,
                    ),
            ),
          ),
        ),
      ],
    );
  }
}
