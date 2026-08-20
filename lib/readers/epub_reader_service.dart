import 'dart:io';

import 'package:epubx/epubx.dart';
import 'package:html/parser.dart' show parse;

import '../core/reader_service.dart';
import '../models/text_chunk.dart';

class EpubReaderService implements ReaderService {
  final List<TextChunk> _chunks = [];
  
  @override
  Future<void> loadDocument(String path) async {
    _chunks.clear();
    
    final File file = File(path);
    final bytes = await file.readAsBytes();
    
    final EpubBook epubBook = await EpubReader.readBook(bytes);
    
    int chunkIndex = 1;
    
    if (epubBook.Chapters != null) {
      for (final chapter in epubBook.Chapters!) {
        chunkIndex = _processChapter(chapter, chunkIndex);
      }
    }
  }
  
  int _processChapter(EpubChapter chapter, int startIndex) {
    int currentIndex = startIndex;
    
    // Clean HTML
    String cleanText = _stripHtml(chapter.HtmlContent ?? '');
    
    if (cleanText.trim().isNotEmpty) {
      // Split into chunks
      final chapterChunks = _smartSplit(cleanText, currentIndex, chapter.Title);
      _chunks.addAll(chapterChunks);
      currentIndex += chapterChunks.length;
    }
    
    if (chapter.SubChapters != null) {
      for (final subChapter in chapter.SubChapters!) {
        currentIndex = _processChapter(subChapter, currentIndex);
      }
    }
    
    return currentIndex;
  }
  
  String _stripHtml(String htmlString) {
    // We want to preserve paragraph breaks.
    // Replace </p> and <br> with newlines before parsing
    String preProcessed = htmlString
        .replaceAll(RegExp(r'</p>', caseSensitive: false), '\n\n')
        .replaceAll(RegExp(r'<br\s*/?>', caseSensitive: false), '\n');
        
    final document = parse(preProcessed);
    return document.body?.text ?? '';
  }
  
  List<TextChunk> _smartSplit(String text, int startIndex, String? title) {
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
          
          if (currentChunkText.length + sentence.length > 2000 && currentChunkText.isNotEmpty) {
            chunks.add(TextChunk(
              index: currentIndex++,
              text: currentChunkText.toString().trim(),
              label: title,
            ));
            currentChunkText.clear();
          }
          currentChunkText.write('$sentence ');
        }
      } else {
        if (currentChunkText.length + paragraph.length > 2000 && currentChunkText.isNotEmpty) {
          chunks.add(TextChunk(
            index: currentIndex++,
            text: currentChunkText.toString().trim(),
            label: title,
          ));
          currentChunkText.clear();
        }
        currentChunkText.write('$paragraph\n\n');
      }
    }
    
    if (currentChunkText.isNotEmpty) {
      chunks.add(TextChunk(
        index: currentIndex++,
        text: currentChunkText.toString().trim(),
        label: title,
      ));
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
