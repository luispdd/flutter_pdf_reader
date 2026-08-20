import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter_tts/flutter_tts.dart';

import '../core/reader_service.dart';
import '../readers/pdf_reader_service.dart';
import '../readers/epub_reader_service.dart';
import '../readers/clipboard_reader_service.dart';

class DocumentReaderController extends ChangeNotifier {
  final FlutterTts _flutterTts = FlutterTts();

  String? _documentPath;
  String? _documentFileName;
  bool _isPdf = false;
  bool _isEpub = false;
  
  ReaderService? _activeReader;
  final ClipboardReaderService _clipboardReader = ClipboardReaderService();

  int _totalChunks = 0;
  int _currentChunk = 1; // 1-indexed for the user UI
  bool _isPlaying = false;
  bool _isReadingClipboard = false;
  bool _isLoading = false;
  String _currentChunkText = "";
  Process? _linuxTtsProcess;

  String? get documentFileName => _documentFileName;
  int get totalChunks => _totalChunks;
  int get currentChunk => _currentChunk;
  bool get isPlaying => _isPlaying;
  bool get isReadingClipboard => _isReadingClipboard;
  bool get isLoading => _isLoading;
  String get currentChunkText => _currentChunkText;
  bool get isPdf => _isPdf;
  bool get isEpub => _isEpub;

  DocumentReaderController() {
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
          _readNextChunk();
        }
      }
    });
  }

  Future<void> pickFile() async {
    try {
      List<PlatformFile> result = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'epub'],
      );

      if (result.isNotEmpty && result.first.path != null) {
        _documentPath = result.first.path!;
        _documentFileName = result.first.name;
        
        final extension = _documentFileName!.split('.').last.toLowerCase();
        _isPdf = extension == 'pdf';
        _isEpub = extension == 'epub';
        
        await _loadDocument();
      }
    } catch (e) {
      // User canceled or error
    }
  }

  Future<void> _loadDocument() async {
    if (_documentPath == null) return;

    _isLoading = true;
    _totalChunks = 0;
    notifyListeners();

    await stopNarration();

    _activeReader?.dispose();
    
    if (_isPdf) {
      _activeReader = PdfReaderService();
    } else if (_isEpub) {
      _activeReader = EpubReaderService();
    } else {
      _isLoading = false;
      notifyListeners();
      return; // Unsupported type
    }

    await _activeReader!.loadDocument(_documentPath!);
    _totalChunks = _activeReader!.totalChunks;
    _currentChunk = 1;
    await _extractTextForCurrentChunk();
    
    _isLoading = false;
    notifyListeners();
  }

  Future<void> setChunk(int chunkIndex) async {
    if (chunkIndex < 1 || chunkIndex > _totalChunks) return;
    _currentChunk = chunkIndex;
    
    _isLoading = true;
    notifyListeners();

    await _extractTextForCurrentChunk();

    _isLoading = false;
    if (_isPlaying) {
      await stopNarration();
    } else {
      notifyListeners();
    }
  }

  Future<void> _extractTextForCurrentChunk() async {
    if (_activeReader == null) return;
    _currentChunkText = await _activeReader!.extractTextForChunk(_currentChunk);
  }

  Future<void> startNarration() async {
    if ((_activeReader == null && !_isReadingClipboard) || _currentChunkText.isEmpty) return;

    if (_isPlaying) {
      await stopNarration();
    }

    _isPlaying = true;
    _isReadingClipboard = false;
    notifyListeners();

    await _startNarrationOfText(_currentChunkText);
  }

  Future<void> readClipboard() async {
    ClipboardData? data = await Clipboard.getData(Clipboard.kTextPlain);
    String text = data?.text ?? '';
    if (text.isNotEmpty) {
      await stopNarration();
      _isReadingClipboard = true;
      _isPlaying = true;
      _clipboardReader.loadText(text);
      _currentChunkText = await _clipboardReader.extractTextForChunk(1);
      notifyListeners();
      await _startNarrationOfText(_currentChunkText);
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
      try {
        final command = '''
echo "\$_TEXT" | piper --model ~/.local/share/piper-voices/en_GB-cori-high.onnx --output-raw | aplay -r 22050 -f S16_LE -t raw -
''';
        final process = await Process.start(
          'bash',
          ['-c', command],
          environment: {'_TEXT': text},
        );
        _linuxTtsProcess = process;

        process.stderr.listen((data) {
          print("TTS Error: ${String.fromCharCodes(data)}");
        });

        process.exitCode.then((code) {
          if (_linuxTtsProcess != process) return;

          if (code == 0 && _isPlaying) {
            if (_isReadingClipboard) {
              _isReadingClipboard = false;
              _isPlaying = false;
              notifyListeners();
            } else {
              _readNextChunk();
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

  void _readNextChunk() async {
    if (_currentChunk < _totalChunks) {
      _currentChunk++;
      await _extractTextForCurrentChunk();
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
    _activeReader?.dispose();
    _clipboardReader.dispose();
    super.dispose();
  }
}
