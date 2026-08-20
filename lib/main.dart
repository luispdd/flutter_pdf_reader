import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'controllers/document_reader_controller.dart';

// ─── Warm Amber Palette ───
const Color _kBgDark = Color(0xFF0C0A09);
const Color _kSurface = Color(0xFF1C1917);
const Color _kAmber = Color(0xFFF59E0B);
const Color _kAmberDark = Color(0xFFD97706);
const Color _kAmberLight = Color(0xFFFBBF24);
const Color _kTextPrimary = Color(0xFFFAFAF9);

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
        theme: ThemeData(
          useMaterial3: true,
          brightness: Brightness.dark,
          scaffoldBackgroundColor: _kBgDark,
          colorScheme: const ColorScheme.dark(
            primary: _kAmber,
            onPrimary: Colors.white,
            secondary: _kAmberDark,
            surface: _kSurface,
            onSurface: _kTextPrimary,
            outline: Color(0xFF292524),
          ),
          appBarTheme: const AppBarTheme(
            backgroundColor: _kSurface,
            elevation: 0,
            centerTitle: false,
            titleTextStyle: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w500,
              color: _kTextPrimary,
              letterSpacing: 0.3,
            ),
          ),
          sliderTheme: SliderThemeData(
            activeTrackColor: _kAmber,
            inactiveTrackColor: Colors.white.withValues(alpha: 0.10),
            thumbColor: Colors.white,
            overlayColor: _kAmber.withValues(alpha: 0.20),
            trackHeight: 4,
            thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 8),
          ),
          dialogTheme: DialogThemeData(
            backgroundColor: _kSurface,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          ),
        ),
        home: const DocumentReaderScreen(),
      ),
    );
  }
}

class _WaveformBars extends StatefulWidget {
  final bool isPlaying;
  const _WaveformBars({required this.isPlaying});

  @override
  State<_WaveformBars> createState() => _WaveformBarsState();
}

class _WaveformBarsState extends State<_WaveformBars>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    if (widget.isPlaying) _ctrl.repeat();
  }

  @override
  void didUpdateWidget(covariant _WaveformBars old) {
    super.didUpdateWidget(old);
    if (widget.isPlaying && !_ctrl.isAnimating) {
      _ctrl.repeat();
    } else if (!widget.isPlaying && _ctrl.isAnimating) {
      _ctrl.stop();
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 36,
      child: AnimatedBuilder(
        animation: _ctrl,
        builder: (context, _) {
          return Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: List.generate(12, (index) {
              final progress = _ctrl.value;
              final offset = (index / 12.0) * 2 * math.pi;
              final wave = widget.isPlaying
                  ? (math.sin(progress * 2 * math.pi + offset).abs() * 0.75 +
                        0.25)
                  : 0.2;
              final barHeight = 6.0 + (wave * 26.0);

              return Container(
                margin: const EdgeInsets.symmetric(horizontal: 2.5),
                width: 3.5,
                height: barHeight,
                decoration: BoxDecoration(
                  color: widget.isPlaying
                      ? _kAmber.withValues(alpha: 0.6 + (wave * 0.4))
                      : Colors.white.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(2),
                ),
              );
            }),
          );
        },
      ),
    );
  }
}

// ─── Gradient primary button ───
class _GradientButton extends StatelessWidget {
  final VoidCallback onPressed;
  final IconData icon;
  final String label;

  const _GradientButton({
    required this.onPressed,
    required this.icon,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [_kAmber, _kAmberDark],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: _kAmber.withValues(alpha: 0.20),
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 18, color: Colors.white),
            const SizedBox(width: 10),
            Text(
              label,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w500,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Secondary dark button ───
class _SecondaryButton extends StatelessWidget {
  final VoidCallback onPressed;
  final IconData icon;
  final String label;

  const _SecondaryButton({
    required this.onPressed,
    required this.icon,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.03),
          border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 18, color: Colors.white.withValues(alpha: 0.65)),
            const SizedBox(width: 10),
            Text(
              label,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w500,
                color: Colors.white.withValues(alpha: 0.65),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Amber outline button ───
class _OutlineButton extends StatelessWidget {
  final VoidCallback onPressed;
  final IconData icon;
  final String label;

  const _OutlineButton({
    required this.onPressed,
    required this.icon,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
        decoration: BoxDecoration(
          border: Border.all(
            color: _kAmber.withValues(alpha: 0.40),
            width: 1.5,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 16, color: _kAmberLight),
            const SizedBox(width: 8),
            Text(
              label,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: _kAmberLight,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class DocumentReaderScreen extends StatelessWidget {
  const DocumentReaderScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<DocumentReaderController>();
    final chunkTypeLabel = controller.isEpub ? 'Chunk' : 'Page';

    // ─── Clipboard takes over the whole screen when active ───
    if (controller.isReadingClipboard) {
      return Scaffold(
        backgroundColor: _kBgDark,
        appBar: AppBar(
          title: const Text('Clipboard Reader'),
          automaticallyImplyLeading: false,
        ),
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: _buildClipboardView(context, controller),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: _kBgDark,
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
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: controller.totalChunks == 0 && !controller.isLoading
              ? _buildEmptyState(context, controller)
              : _buildPlayerState(context, controller, chunkTypeLabel),
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════
  //  EMPTY STATE
  // ═══════════════════════════════════════════════════════════
  Widget _buildEmptyState(BuildContext ctx, DocumentReaderController c) {
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
                colors: [_kAmber, _kAmberDark],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: _kAmber.withValues(alpha: 0.20),
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
            color: _kTextPrimary,
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
        _GradientButton(
          onPressed: () => c.pickFile(),
          icon: Icons.file_upload,
          label: 'Select PDF or EPUB file',
        ),
        const SizedBox(height: 12),
        _SecondaryButton(
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
        const Spacer(flex: 3),
      ],
    );
  }

  // ═══════════════════════════════════════════════════════════
  //  PLAYER STATE
  // ═══════════════════════════════════════════════════════════
  Widget _buildPlayerState(
    BuildContext ctx,
    DocumentReaderController c,
    String chunkTypeLabel,
  ) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (c.isLoading && c.totalChunks == 0)
            const SizedBox(
              height: 400,
              child: Center(child: CircularProgressIndicator(color: _kAmber)),
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
                  color: _kAmber.withValues(alpha: 0.10),
                  border: Border.all(color: _kAmber.withValues(alpha: 0.18)),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.insert_drive_file_outlined,
                      size: 20,
                      color: _kAmberLight,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        c.documentFileName!,
                        style: TextStyle(fontSize: 13, color: _kAmberLight),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 24),

            // Page / Chunk selector
            if (c.totalChunks > 0) ...[
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
                        value: c.currentChunk,
                        dropdownColor: _kSurface,
                        menuMaxHeight: 300,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w500,
                          color: _kTextPrimary,
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
              const SizedBox(height: 16),

              // Slider
              Slider(
                value: c.currentChunk.toDouble(),
                min: 1,
                max: c.totalChunks.toDouble(),
                divisions: c.totalChunks > 1 ? c.totalChunks - 1 : 1,
                label: c.currentChunk.toString(),
                onChanged: (value) => c.setChunk(value.toInt()),
              ),
              const SizedBox(height: 8),

              // Waveform
              _WaveformBars(isPlaying: c.isPlaying),
              const SizedBox(height: 20),

              // Play / Stop button
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
                        colors: [_kAmber, _kAmberDark],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: _kAmber.withValues(alpha: 0.25),
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
              const SizedBox(height: 24),

              // Show text → now pushes a full-screen page
              _OutlineButton(
                onPressed: () => _pushTextView(ctx, c, chunkTypeLabel),
                icon: Icons.text_snippet_outlined,
                label: 'Show $chunkTypeLabel text',
              ),
              const SizedBox(height: 12),
            ],

            // Upload another
            _SecondaryButton(
              onPressed: () => c.pickFile(),
              icon: Icons.file_upload,
              label: 'Select another file',
            ),
            const SizedBox(height: 12),

            // Clipboard
            _SecondaryButton(
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
  //  CLIPBOARD VIEW  (full screen, replaces everything)
  // ═══════════════════════════════════════════════════════════
  Widget _buildClipboardView(BuildContext ctx, DocumentReaderController c) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 40),
        Center(
          child: Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [_kAmber, _kAmberDark],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: _kAmber.withValues(alpha: 0.20),
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
            color: _kTextPrimary,
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
        _WaveformBars(isPlaying: c.isReadingClipboard),
        const SizedBox(height: 24),
        Center(
          child: GestureDetector(
            onTap: () => c.stopClipboardNarration(),
            child: Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [_kAmber, _kAmberDark],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: _kAmber.withValues(alpha: 0.25),
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
        _SecondaryButton(
          onPressed: () => c.stopClipboardNarration(),
          icon: Icons.arrow_back,
          label: 'Back to home',
        ),
      ],
    );
  }

  // ═══════════════════════════════════════════════════════════
  //  TEXT VIEW  (pushed as a full-screen route)
  // ═══════════════════════════════════════════════════════════
  void _pushTextView(
    BuildContext ctx,
    DocumentReaderController c,
    String chunkTypeLabel,
  ) {
    Navigator.of(ctx).push(
      MaterialPageRoute(
        builder: (_) => Scaffold(
          backgroundColor: _kBgDark,
          appBar: AppBar(
            title: Text('$chunkTypeLabel ${c.currentChunk}'),
            leading: IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () => Navigator.of(ctx).pop(),
            ),
          ),
          body: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
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
      ),
    );
  }
}
