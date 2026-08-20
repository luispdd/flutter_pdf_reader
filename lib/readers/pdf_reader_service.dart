import 'dart:io';
import 'dart:typed_data';

import 'package:syncfusion_flutter_pdf/pdf.dart';

import '../core/reader_service.dart';

class PdfReaderService implements ReaderService {
  PdfDocument? _document;
  int _totalPages = 0;
  static const List<String> _charactersToRemove = ['●'];

  @override
  Future<void> loadDocument(String path) async {
    final File file = File(path);
    final Uint8List bytes = await file.readAsBytes();

    _document = PdfDocument(inputBytes: bytes);
    _totalPages = _document!.pages.count;
  }

  @override
  int get totalChunks => _totalPages;

  @override
  Future<String> extractTextForChunk(int index) async {
    if (_document == null || index < 1 || index > _totalPages) {
      return "Error extracting text from this page.";
    }

    try {
      final PdfTextExtractor extractor = PdfTextExtractor(_document!);
      // extractText uses 0-based indexing for pages
      final String extractedText = extractor.extractText(
        startPageIndex: index - 1,
        endPageIndex: index - 1,
      );
      final List<String> pageNumbers = [
        if (index > 1) (index - 1).toString(),
        index.toString(),
        (index + 1).toString(),
      ];

      final String escapedPageNumbers = pageNumbers
          .map((p) => RegExp.escape(p.toString()))
          .join('|');

      final RegExp startRegExp = RegExp(
        r'^(?:' + escapedPageNumbers + r')\b\s*',
      );
      final RegExp endRegExp = RegExp(r'\s*\b(?:' + escapedPageNumbers + r')$');

      final textWithoutPageNumber = extractedText
          .trim()
          .replaceFirst(startRegExp, '')
          .replaceFirst(endRegExp, '')
          .trim();

      return _removeCharactersFromText(textWithoutPageNumber);
    } catch (e) {
      return "Error extracting text from this page.";
    }
  }

  String _removeCharactersFromText(String text) {
    var cleanedText = text;
    for (final character in _charactersToRemove) {
      cleanedText = cleanedText.replaceAll(character, '');
    }
    return cleanedText;
  }

  @override
  void dispose() {
    _document?.dispose();
    _document = null;
  }
}
