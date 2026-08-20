import '../core/reader_service.dart';

class ClipboardReaderService implements ReaderService {
  String _text = '';

  @override
  Future<void> loadDocument(String path) async {
    // Not used for clipboard
  }
  
  void loadText(String text) {
    _text = text;
  }

  @override
  int get totalChunks => 1;

  @override
  Future<String> extractTextForChunk(int index) async {
    return _text;
  }

  @override
  void dispose() {
    _text = '';
  }
}
