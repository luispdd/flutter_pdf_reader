import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:file_picker/file_picker.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';
import 'package:flutter_tts/flutter_tts.dart';

class PdfReaderController extends ChangeNotifier {
  final FlutterTts _flutterTts = FlutterTts();

  String? _pdfPath;
  String? _pdfFileName;
  int _totalPages = 0;
  int _currentPage = 1; // 1-indexed for the user UI
  bool _isPlaying = false;
  bool _isReadingClipboard = false;
  String _currentPageText = "";
  PdfDocument? _document;
  static const List<String> _charactersToRemove = ['●'];

  String? get pdfFileName => _pdfFileName;
  int get totalPages => _totalPages;
  int get currentPage => _currentPage;
  bool get isPlaying => _isPlaying;
  bool get isReadingClipboard => _isReadingClipboard;
  String get currentPageText => _currentPageText;

  PdfReaderController() {
    _initTts();
  }

  void _initTts() {
    _flutterTts.setCompletionHandler(() {
      if (_isPlaying) {
        if (_isReadingClipboard) {
          _isReadingClipboard = false;
          _isPlaying = false;
          notifyListeners();
        } else {
          _readNextPage();
        }
      }
    });
  }

  Future<void> pickFile() async {
    try {
      List<PlatformFile> result = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf'],
      );

      if (result.isNotEmpty && result.first.path != null) {
        _pdfPath = result.first.path!;
        _pdfFileName = result.first.name;
        await _loadDocument();
      }
    } catch (e) {
      // User canceled or error
    }
  }

  Future<void> _loadDocument() async {
    if (_pdfPath == null) return;

    stopNarration();

    final File file = File(_pdfPath!);
    final Uint8List bytes = await file.readAsBytes();

    _document = PdfDocument(inputBytes: bytes);
    _totalPages = _document!.pages.count;
    _currentPage = 1;
    await _extractTextForCurrentPage();
    notifyListeners();
  }

  Future<void> setPage(int page) async {
    if (page < 1 || page > _totalPages) return;
    _currentPage = page;
    await _extractTextForCurrentPage();

    if (_isPlaying) {
      await stopNarration();
      await startNarration();
    } else {
      notifyListeners();
    }
  }

  Future<void> _extractTextForCurrentPage() async {
    if (_document == null) return;

    try {
      final PdfTextExtractor extractor = PdfTextExtractor(_document!);
      // extractText uses 0-based indexing for pages
      final String extractedText = extractor.extractText(
        startPageIndex: _currentPage - 1,
        endPageIndex: _currentPage - 1,
      );
      final List<String> pageNumbers = [
        if (_currentPage > 1) (_currentPage - 1).toString(),
        _currentPage.toString(),
        (_currentPage + 1).toString(),
      ];

      // Works whether pageNumbers is List<int> or List<String>
      final String escapedPageNumbers = pageNumbers
          .map((p) => RegExp.escape(p.toString()))
          .join('|');

      // Uses raw strings (r'...') so \ and $ don't conflict with Dart syntax
      final RegExp startRegExp = RegExp(
        r'^(?:' + escapedPageNumbers + r')\b\s*',
      );
      final RegExp endRegExp = RegExp(r'\s*\b(?:' + escapedPageNumbers + r')$');

      final textWithoutPageNumber = extractedText
          .trim()
          .replaceFirst(startRegExp, '')
          .replaceFirst(endRegExp, '')
          .trim();

      _currentPageText = _removeCharactersFromText(textWithoutPageNumber);
    } catch (e) {
      _currentPageText = "Error extracting text from this page.";
    }
  }

  String _removeCharactersFromText(String text) {
    var cleanedText = text;
    for (final character in _charactersToRemove) {
      cleanedText = cleanedText.replaceAll(character, '');
    }
    return cleanedText;
  }

  Process? _linuxTtsProcess;

  Future<void> startNarration() async {
    if (_document == null || _currentPageText.isEmpty) return;

    if (_isPlaying) {
      await stopNarration();
    }

    _isPlaying = true;
    _isReadingClipboard = false;
    notifyListeners();

    await _startNarrationOfText(_currentPageText);
  }

  Future<void> readClipboard() async {
    ClipboardData? data = await Clipboard.getData(Clipboard.kTextPlain);
    String text = data?.text ?? '';
    if (text.isNotEmpty) {
      await stopNarration();
      _isReadingClipboard = true;
      _isPlaying = true;
      notifyListeners();
      await _startNarrationOfText(text);
    }
  }

  Future<void> stopClipboardNarration() async {
    _isReadingClipboard = false;
    await stopNarration();
  }

  Future<void> _startNarrationOfText(String text) async {
    if (kIsWeb || !Platform.isLinux) {
      await _flutterTts.speak(text);
    } else {
      // Linux fallback since flutter_tts doesn't support Linux.
      // We will try to use 'piper' via bash.
      // You must edit the command below to point to your piper model.
      try {
        // Here we pipe the text into piper and then to aplay.
        // If piper is not configured properly, you might want to replace this with:
        // 'spd-say "\$_TEXT"' or 'espeak "\$_TEXT"'
        final command = '''
echo "\$_TEXT" | piper --model ~/.local/share/piper-voices/en_GB-cori-high.onnx --output-raw | aplay -r 22050 -f S16_LE -t raw -
''';
        final process = await Process.start(
          'bash',
          ['-c', command],
          environment: {'_TEXT': text},
        );
        _linuxTtsProcess = process;

        // Print any errors from the bash command
        process.stderr.listen((data) {
          print("TTS Error: ${String.fromCharCodes(data)}");
        });

        process.exitCode.then((code) {
          // If a new process was started, ignore the exit of the old one
          if (_linuxTtsProcess != process) return;

          if (code == 0 && _isPlaying) {
            if (_isReadingClipboard) {
              _isReadingClipboard = false;
              _isPlaying = false;
              notifyListeners();
            } else {
              _readNextPage();
            }
          } else if (code != 0 && _isPlaying) {
            print("TTS process exited with code $code. Stopping narration.");
            _isPlaying = false;
            _isReadingClipboard = false;
            notifyListeners();
          }
        });
      } catch (e) {
        print("Linux TTS Start Error: $e");
        _isPlaying = false;
        _isReadingClipboard = false;
        notifyListeners();
      }
    }
  }

  Future<void> stopNarration() async {
    _isPlaying = false;
    _isReadingClipboard = false;
    if (kIsWeb || !Platform.isLinux) {
      await _flutterTts.stop();
    } else {
      if (_linuxTtsProcess != null) {
        // Kill child processes (piper, aplay) BEFORE killing the bash shell.
        // Otherwise, they become orphans and continue playing audio!
        await Process.run('pkill', [
          '-9',
          '-P',
          _linuxTtsProcess!.pid.toString(),
        ]);
        _linuxTtsProcess!.kill();
        _linuxTtsProcess = null;
      }
    }
    notifyListeners();
  }

  void _readNextPage() async {
    if (_currentPage < _totalPages) {
      _currentPage++;
      await _extractTextForCurrentPage();
      notifyListeners();
      await startNarration();
    } else {
      _isPlaying = false;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    stopNarration();
    _document?.dispose();
    super.dispose();
  }
}
