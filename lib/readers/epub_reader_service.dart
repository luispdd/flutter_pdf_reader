import 'dart:convert';
import 'dart:io';
import 'dart:isolate';

import 'package:archive/archive.dart';
import 'package:epubx/epubx.dart';
import 'package:html/parser.dart' show parse;

import '../core/reader_service.dart';
import '../models/text_chunk.dart';

class EpubReaderService implements ReaderService {
  final bool filterCode;
  final List<TextChunk> _chunks = [];

  EpubReaderService({this.filterCode = false});

  @override
  Future<void> loadDocument(String path) async {
    _chunks.clear();

    final parsedChunks = await Isolate.run(
      () => _parseEpubFile(path, filterCode),
    );
    _chunks.addAll(parsedChunks);
  }

  static Future<List<TextChunk>> _parseEpubFile(
    String path,
    bool filterCode,
  ) async {
    final File file = File(path);
    final bytes = await file.readAsBytes();

    final List<TextChunk> chunks = [];
    final Set<String> processedContentFiles = {};
    int chunkIndex = 1;

    try {
      // Use openBook instead of readBook to avoid prematurely decompressing
      // non-text assets (images, fonts, scripts like kobo.js) listed in the manifest.
      final EpubBookRef bookRef = await EpubReader.openBook(bytes);

      List<EpubChapterRef> chapterRefs = [];
      try {
        chapterRefs = await bookRef.getChapters();
      } catch (_) {
        // Navigation parsing might fail on non-standard TOCs
      }

      if (chapterRefs.isNotEmpty) {
        for (final chapter in chapterRefs) {
          chunkIndex = await _processChapterRef(
            chapterRef: chapter,
            bookRef: bookRef,
            startIndex: chunkIndex,
            chunks: chunks,
            processedContentFiles: processedContentFiles,
            filterCode: filterCode,
          );
        }
      } else {
        // Fallback to spine items if navigation TOC is absent or empty
        chunkIndex = _processSpineItems(
          bookRef: bookRef,
          startIndex: chunkIndex,
          chunks: chunks,
          processedContentFiles: processedContentFiles,
          filterCode: filterCode,
        );
      }
    } catch (_) {
      // If openBook fails entirely (e.g. invalid container or TOC xml),
      // fallback to raw archive parsing of html/xhtml files
      chunkIndex = _processArchiveDirectly(
        bytes: bytes,
        startIndex: chunkIndex,
        chunks: chunks,
        filterCode: filterCode,
      );
    }

    return chunks;
  }

  static Future<int> _processChapterRef({
    required EpubChapterRef chapterRef,
    required EpubBookRef bookRef,
    required int startIndex,
    required List<TextChunk> chunks,
    required Set<String> processedContentFiles,
    required bool filterCode,
  }) async {
    int currentIndex = startIndex;

    final contentFileName = chapterRef.ContentFileName;
    final isNewFile =
        contentFileName == null || processedContentFiles.add(contentFileName);

    if (isNewFile) {
      final htmlContent = await _safeReadChapterHtml(chapterRef, bookRef);
      final cleanText = _stripHtml(htmlContent, filterCode: filterCode);

      if (cleanText.trim().isNotEmpty) {
        final chapterChunks = _smartSplit(
          cleanText,
          currentIndex,
          chapterRef.Title,
        );
        chunks.addAll(chapterChunks);
        currentIndex += chapterChunks.length;
      }
    }

    if (chapterRef.SubChapters != null) {
      for (final subChapter in chapterRef.SubChapters!) {
        currentIndex = await _processChapterRef(
          chapterRef: subChapter,
          bookRef: bookRef,
          startIndex: currentIndex,
          chunks: chunks,
          processedContentFiles: processedContentFiles,
          filterCode: filterCode,
        );
      }
    }

    return currentIndex;
  }

  static Future<String> _safeReadChapterHtml(
    EpubChapterRef chapterRef,
    EpubBookRef bookRef,
  ) async {
    try {
      final content = await chapterRef.readHtmlContent();
      if (content.isNotEmpty) {
        return content;
      }
    } catch (_) {}

    // Fallback: search archive directly with normalized paths
    final archive = bookRef.EpubArchive();
    if (archive != null && chapterRef.ContentFileName != null) {
      final content = _findFileContentInArchive(
        archive: archive,
        contentDirectoryPath: bookRef.Schema?.ContentDirectoryPath,
        fileName: chapterRef.ContentFileName!,
      );
      if (content != null) {
        return content;
      }
    }

    return '';
  }

  static int _processSpineItems({
    required EpubBookRef bookRef,
    required int startIndex,
    required List<TextChunk> chunks,
    required Set<String> processedContentFiles,
    required bool filterCode,
  }) {
    int currentIndex = startIndex;
    final spineItems = bookRef.Schema?.Package?.Spine?.Items;
    final manifestItems = bookRef.Schema?.Package?.Manifest?.Items;
    final archive = bookRef.EpubArchive();
    if (spineItems == null || manifestItems == null || archive == null) {
      return currentIndex;
    }

    final manifestMap = <String, String>{};
    for (final item in manifestItems) {
      if (item.Id != null && item.Href != null) {
        manifestMap[item.Id!] = item.Href!;
      }
    }

    for (final spineItem in spineItems) {
      final idRef = spineItem.IdRef;
      if (idRef == null) continue;
      final href = manifestMap[idRef];
      if (href == null) continue;

      if (!processedContentFiles.add(href)) continue;

      final htmlContent = _findFileContentInArchive(
        archive: archive,
        contentDirectoryPath: bookRef.Schema?.ContentDirectoryPath,
        fileName: href,
      );
      if (htmlContent == null || htmlContent.trim().isEmpty) continue;

      final cleanText = _stripHtml(htmlContent, filterCode: filterCode);
      if (cleanText.trim().isNotEmpty) {
        final chapterChunks = _smartSplit(cleanText, currentIndex, null);
        chunks.addAll(chapterChunks);
        currentIndex += chapterChunks.length;
      }
    }

    return currentIndex;
  }

  static int _processArchiveDirectly({
    required List<int> bytes,
    required int startIndex,
    required List<TextChunk> chunks,
    required bool filterCode,
  }) {
    int currentIndex = startIndex;
    try {
      final archive = ZipDecoder().decodeBytes(bytes);
      final htmlFiles = archive.files.where((f) {
        final lower = f.name.toLowerCase();
        return (lower.endsWith('.html') ||
                lower.endsWith('.xhtml') ||
                lower.endsWith('.htm')) &&
            !lower.contains('toc') &&
            !lower.contains('nav');
      }).toList();

      htmlFiles.sort((a, b) => a.name.compareTo(b.name));

      for (final file in htmlFiles) {
        if (file.content == null) continue;
        try {
          final content = utf8.decode(
            file.content as List<int>,
            allowMalformed: true,
          );
          final cleanText = _stripHtml(content, filterCode: filterCode);
          if (cleanText.trim().isNotEmpty) {
            final chapterChunks = _smartSplit(cleanText, currentIndex, null);
            chunks.addAll(chapterChunks);
            currentIndex += chapterChunks.length;
          }
        } catch (_) {}
      }
    } catch (_) {}

    return currentIndex;
  }

  static String? _findFileContentInArchive({
    required Archive archive,
    required String? contentDirectoryPath,
    required String fileName,
  }) {
    final combined =
        (contentDirectoryPath != null && contentDirectoryPath.isNotEmpty)
        ? '$contentDirectoryPath/$fileName'
        : fileName;
    final normalized = _normalizePath(combined);
    final normalizedFileName = _normalizePath(fileName);

    ArchiveFile? matchedFile;

    // 1. Exact or normalized path match
    for (final file in archive.files) {
      final archiveName = _normalizePath(file.name);
      if (archiveName == normalized ||
          file.name == combined ||
          archiveName == normalizedFileName ||
          file.name == fileName) {
        matchedFile = file;
        break;
      }
    }

    // 2. Case-insensitive match
    if (matchedFile == null) {
      final normLower = normalized.toLowerCase();
      final normFileLower = normalizedFileName.toLowerCase();
      for (final file in archive.files) {
        final archiveLower = _normalizePath(file.name).toLowerCase();
        if (archiveLower == normLower || archiveLower == normFileLower) {
          matchedFile = file;
          break;
        }
      }
    }

    // 3. Basename suffix match (e.g. chapter1.xhtml)
    if (matchedFile == null) {
      final baseName = normalizedFileName.split('/').last.toLowerCase();
      for (final file in archive.files) {
        if (_normalizePath(file.name).toLowerCase().endsWith('/$baseName') ||
            file.name.toLowerCase() == baseName) {
          matchedFile = file;
          break;
        }
      }
    }

    if (matchedFile != null && matchedFile.content != null) {
      try {
        final bytes = matchedFile.content as List<int>;
        return utf8.decode(bytes, allowMalformed: true);
      } catch (_) {}
    }
    return null;
  }

  static String _normalizePath(String rawPath) {
    String p = rawPath.replaceAll(r'\', '/');
    try {
      p = Uri.decodeFull(p);
    } catch (_) {}

    final parts = p.split('/');
    final resolved = <String>[];
    for (final part in parts) {
      if (part.isEmpty || part == '.') continue;
      if (part == '..') {
        if (resolved.isNotEmpty) {
          resolved.removeLast();
        }
      } else {
        resolved.add(part);
      }
    }
    return resolved.join('/');
  }

  static String _stripHtml(String htmlString, {required bool filterCode}) {
    // Preserve paragraph breaks: replace </p> and <br> with newlines before parsing
    final String preProcessed = htmlString
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

  static List<TextChunk> _smartSplit(
    String text,
    int startIndex,
    String? title,
  ) {
    final List<TextChunk> chunks = [];
    int currentIndex = startIndex;

    // 1. Split by paragraphs first
    final paragraphs = text.split('\n\n');

    final StringBuffer currentChunkText = StringBuffer();

    for (String paragraph in paragraphs) {
      paragraph = paragraph.trim();
      if (paragraph.isEmpty) continue;

      // If a single paragraph is too long, we need to split it by sentences
      if (paragraph.length > 2000) {
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
