import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/reader_service.dart';
import '../readers/pdf_reader_service.dart';
import '../readers/epub_reader_service.dart';
import '../readers/clipboard_reader_service.dart';

class DocumentReaderController extends ChangeNotifier {
  static const String _keyDocumentPath = 'last_document_path';
  static const String _keyDocumentFileName = 'last_document_name';
  static const String _keyCurrentChunk = 'last_chunk_index';
  static const String _keySpeechRate = 'narration_speed';
  static const String _keySpeechLanguage = 'narration_language';

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
  double _speechRate = 1.0;
  String? _speechLanguage;
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
  double get speechRate => _speechRate;
  String? get speechLanguage => _speechLanguage;

  DocumentReaderController({bool autoRestore = true}) {
    _initTts();
    if (autoRestore) {
      _restoreSettings();
      _restoreLastSession();
    }
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

  Future<void> _restoreSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedRate = prefs.getDouble(_keySpeechRate);
      if (savedRate != null) {
        _speechRate = savedRate;
        try {
          await _flutterTts.setSpeechRate(_speechRate);
        } catch (_) {}
      }
      final savedLanguage = prefs.getString(_keySpeechLanguage);
      if (savedLanguage != null && savedLanguage.isNotEmpty) {
        _speechLanguage = savedLanguage;
        try {
          await _flutterTts.setLanguage(_speechLanguage!);
        } catch (_) {}
      }
      notifyListeners();
    } catch (e) {
      debugPrint("Error restoring settings: $e");
    }
  }

  Future<List<String>> getAvailableLanguages() async {
    try {
      final dynamic languages = await _flutterTts.getLanguages;
      if (languages is List) {
        final list = languages.map((e) => e.toString()).toSet().toList();
        list.sort();
        return list;
      }
    } catch (e) {
      debugPrint("Error fetching languages: $e");
    }
    return [];
  }

  Future<void> updateSpeechSettings({
    required double speechRate,
    String? language,
  }) async {
    _speechRate = speechRate;
    _speechLanguage = language;
    try {
      await _flutterTts.setSpeechRate(_speechRate);
    } catch (_) {}
    try {
      if (_speechLanguage != null && _speechLanguage!.isNotEmpty) {
        await _flutterTts.setLanguage(_speechLanguage!);
      }
    } catch (_) {}
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setDouble(_keySpeechRate, _speechRate);
      if (_speechLanguage != null && _speechLanguage!.isNotEmpty) {
        await prefs.setString(_keySpeechLanguage, _speechLanguage!);
      } else {
        await prefs.remove(_keySpeechLanguage);
      }
    } catch (e) {
      debugPrint("Error updating speech settings: $e");
    }
    notifyListeners();
  }

  Future<void> _restoreLastSession() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedPath = prefs.getString(_keyDocumentPath);
      final savedFileName = prefs.getString(_keyDocumentFileName);
      final savedChunk = prefs.getInt(_keyCurrentChunk) ?? 1;

      if (savedPath != null && savedPath.isNotEmpty) {
        final file = File(savedPath);
        if (await file.exists()) {
          _documentPath = savedPath;
          _documentFileName = savedFileName ?? savedPath.split(Platform.pathSeparator).last;
          
          final extension = _documentFileName!.split('.').last.toLowerCase();
          _isPdf = extension == 'pdf';
          _isEpub = extension == 'epub';

          if (_isPdf || _isEpub) {
            await _loadDocument(initialChunk: savedChunk);
            return;
          }
        }
        // File doesn't exist or has unsupported extension, clean up saved preferences
        await _clearSavedSession();
      }
    } catch (e) {
      debugPrint("Error restoring last session: $e");
    }
  }

  Future<void> _saveCurrentSession() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (_documentPath != null) {
        await prefs.setString(_keyDocumentPath, _documentPath!);
        if (_documentFileName != null) {
          await prefs.setString(_keyDocumentFileName, _documentFileName!);
        }
        await prefs.setInt(_keyCurrentChunk, _currentChunk);
      }
    } catch (e) {
      debugPrint("Error saving session: $e");
    }
  }

  Future<void> _saveCurrentChunk() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(_keyCurrentChunk, _currentChunk);
    } catch (e) {
      debugPrint("Error saving chunk: $e");
    }
  }

  Future<void> _clearSavedSession() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_keyDocumentPath);
      await prefs.remove(_keyDocumentFileName);
      await prefs.remove(_keyCurrentChunk);
    } catch (e) {
      debugPrint("Error clearing session: $e");
    }
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
        
        await _loadDocument(initialChunk: 1);
      }
    } catch (e) {
      // User canceled or error
    }
  }

  Future<void> _loadDocument({int initialChunk = 1}) async {
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

    try {
      await _activeReader!.loadDocument(_documentPath!);
      _totalChunks = _activeReader!.totalChunks;
      if (_totalChunks > 0) {
        _currentChunk = initialChunk.clamp(1, _totalChunks);
        await _extractTextForCurrentChunk();
        await _saveCurrentSession();
      } else {
        _currentChunk = 1;
        _currentChunkText = "";
      }
    } catch (e) {
      debugPrint("Error loading document: $e");
      _totalChunks = 0;
      _currentChunk = 1;
      _currentChunkText = "";
      await _clearSavedSession();
    }
    
    _isLoading = false;
    notifyListeners();
  }

  Future<void> setChunk(int chunkIndex) async {
    if (chunkIndex < 1 || chunkIndex > _totalChunks) return;
    _currentChunk = chunkIndex;
    
    _isLoading = true;
    notifyListeners();

    await _extractTextForCurrentChunk();
    await _saveCurrentChunk();

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
        final home = Platform.environment['HOME'] ?? '';
        final modelPath = '$home/.local/share/piper-voices/en_GB-cori-high.onnx';
        final lengthScale = (_speechRate > 0 ? (1.0 / _speechRate) : 1.0).toStringAsFixed(2);
        final command = '''
set -o pipefail
export PATH="\$HOME/.local/bin:\$HOME/.local/share/piper:/usr/local/bin:/usr/bin:/bin:\$PATH"
echo "\$_TEXT" | piper --model "$modelPath" --length-scale \$LENGTH_SCALE --output-raw | aplay -r 22050 -f S16_LE -t raw -
''';
        final process = await Process.start(
          'bash',
          ['-c', command],
          environment: {
            '_TEXT': text,
            'LENGTH_SCALE': lengthScale,
            if (home.isNotEmpty) 'HOME': home,
          },
        );
        _linuxTtsProcess = process;

        process.stderr.listen((data) {
          debugPrint("TTS Error: ${String.fromCharCodes(data)}");
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
            debugPrint("TTS process exited with code $code. Stopping narration.");
            _isPlaying = false;
            _isReadingClipboard = false;
            notifyListeners();
          }
        });
      } catch (e) {
        debugPrint("Linux TTS Start Error: $e");
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
      await _saveCurrentChunk();
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
