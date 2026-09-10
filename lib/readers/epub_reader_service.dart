import 'dart:io';
import 'dart:isolate';

import 'package:epubx/epubx.dart';
import 'package:html/parser.dart' show parse;

import '../core/reader_service.dart';
import '../models/text_chunk.dart';

class EpubReaderService implements ReaderService {
  final bool filterCode;
  final List<TextChunk> _chunks = [];
  final Set<String> _processedContentFiles = {};

  EpubReaderService({this.filterCode = false});

  @override
  Future<void> loadDocument(String path) async {
    _chunks.clear();
    _processedContentFiles.clear();

    final parsedChunks = await Isolate.run(() => _parseEpubFile(path, filterCode));
    _chunks.addAll(parsedChunks);
  }

  static Future<List<TextChunk>> _parseEpubFile(String path, bool filterCode) async {
    final File file = File(path);
    final bytes = await file.readAsBytes();

    final EpubBook epubBook = await EpubReader.readBook(bytes);

    final List<TextChunk> chunks = [];
    final Set<String> processedContentFiles = {};
    int chunkIndex = 1;

    if (epubBook.Chapters != null) {
      for (final chapter in epubBook.Chapters!) {
        chunkIndex = _processChapter(
          chapter: chapter,
          startIndex: chunkIndex,
          chunks: chunks,
          processedContentFiles: processedContentFiles,
          filterCode: filterCode,
        );
      }
    }

    return chunks;
  }

  static int _processChapter({
    required EpubChapter chapter,
    required int startIndex,
    required List<TextChunk> chunks,
    required Set<String> processedContentFiles,
    required bool filterCode,
  }) {
    int currentIndex = startIndex;

    final contentFileName = chapter.ContentFileName;
    if (contentFileName != null &&
        !processedContentFiles.add(contentFileName)) {
      return currentIndex;
    }

    // Clean HTML
    String cleanText = _stripHtml(chapter.HtmlContent ?? '', filterCode: filterCode);

    if (cleanText.trim().isNotEmpty) {
      // Split into chunks
      final chapterChunks = _smartSplit(cleanText, currentIndex, chapter.Title);
      chunks.addAll(chapterChunks);
      currentIndex += chapterChunks.length;
    }

    if (chapter.SubChapters != null) {
      for (final subChapter in chapter.SubChapters!) {
        currentIndex = _processChapter(
          chapter: subChapter,
          startIndex: currentIndex,
          chunks: chunks,
          processedContentFiles: processedContentFiles,
          filterCode: filterCode,
        );
      }
    }

    return currentIndex;
  }

  static String _stripHtml(String htmlString, {required bool filterCode}) {
    // We want to preserve paragraph breaks.
    // Replace </p> and <br> with newlines before parsing
    String preProcessed = htmlString
        .replaceAll(RegExp(r'</p>', caseSensitive: false), '\n\n')
        .replaceAll(RegExp(r'<br\s*/?>', caseSensitive: false), '\n');

    final document = parse(preProcessed);

    if (filterCode) {
      const codeSelectors = [
        'code',
        '.code',
        '.code-block',
        '.codeblock',
        '.sourceCode',
        '.source-code',
        '.programlisting',
        '.program-listing',
      ];
      final elementsToRemove = document.querySelectorAll(
        codeSelectors.join(', '),
      );
      for (final element in elementsToRemove) {
        element.remove();
      }
    }

    return document.body?.text ?? '';
  }

  static List<TextChunk> _smartSplit(String text, int startIndex, String? title) {
    final List<TextChunk> chunks = [];
    int currentIndex = startIndex;

    // 1. Split by paragraphs first
    final paragraphs = text.split('\n\n');

    StringBuffer currentChunkText = StringBuffer();

    for (String paragraph in paragraphs) {
      paragraph = paragraph.trim();
      if (paragraph.isEmpty) continue;

      // If a single paragraph is too long, we need to split it by sentences
      if (paragraph.length > 2000) {
        // Split by sentences (. ? !)
        final sentences = paragraph.split(RegExp(r'(?<=[.?!])\s+'));
        for (String sentence in sentences) {
          sentence = sentence.trim();
          if (sentence.isEmpty) continue;

          if (currentChunkText.length + sentence.length > 2000 &&
              currentChunkText.isNotEmpty) {
            chunks.add(
              TextChunk(
                index: currentIndex++,
                text: currentChunkText.toString().trim(),
                label: title,
              ),
            );
            currentChunkText.clear();
          }
          currentChunkText.write('$sentence ');
        }
      } else {
        if (currentChunkText.length + paragraph.length > 2000 &&
            currentChunkText.isNotEmpty) {
          chunks.add(
            TextChunk(
              index: currentIndex++,
              text: currentChunkText.toString().trim(),
              label: title,
            ),
          );
          currentChunkText.clear();
        }
        currentChunkText.write('$paragraph\n\n');
      }
    }

    if (currentChunkText.isNotEmpty) {
      chunks.add(
        TextChunk(
          index: currentIndex++,
          text: currentChunkText.toString().trim(),
          label: title,
        ),
      );
    }

    return chunks;
  }

  @override
  int get totalChunks => _chunks.length;

  @override
  Future<String> extractTextForChunk(int index) async {
    if (index < 1 || index > _chunks.length) {
      return "Error extracting text for this chunk.";
    }
    return _chunks[index - 1].text;
  }

  @override
  void dispose() {
    _chunks.clear();
  }
}
