import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';

import 'package:flutter_pdf_reader/controllers/document_reader_controller.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    const MethodChannel ttsChannel = MethodChannel('flutter_tts');
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(ttsChannel, (MethodCall call) async {
          switch (call.method) {
            case 'getLanguages':
              return ['en-US', 'en-GB', 'es-ES', 'fr-FR'];
            default:
              return 1;
          }
        });
  });

  late Directory tempDir;
  late File samplePdfFile;

  setUpAll(() async {
    tempDir = await Directory.systemTemp.createTemp('flutter_pdf_reader_test_');
    samplePdfFile = File('${tempDir.path}/test_sample.pdf');

    // Generate a simple 3-page PDF for testing
    final document = PdfDocument();
    final page1 = document.pages.add();
    page1.graphics.drawString(
      'Hello from Page One',
      PdfStandardFont(PdfFontFamily.helvetica, 12),
    );
    final page2 = document.pages.add();
    page2.graphics.drawString(
      'Hello from Page Two',
      PdfStandardFont(PdfFontFamily.helvetica, 12),
    );
    final page3 = document.pages.add();
    page3.graphics.drawString(
      'Hello from Page Three',
      PdfStandardFont(PdfFontFamily.helvetica, 12),
    );

    final bytes = document.saveSync();
    document.dispose();
    await samplePdfFile.writeAsBytes(bytes);
  });

  tearDownAll(() async {
    if (await tempDir.exists()) {
      await tempDir.delete(recursive: true);
    }
  });

  test('Starts with empty state when no preferences exist', () async {
    SharedPreferences.setMockInitialValues({});
    final controller = DocumentReaderController();

    // Allow async _restoreLastSession to complete
    await Future.delayed(const Duration(milliseconds: 50));

    expect(controller.documentFileName, isNull);
    expect(controller.totalChunks, 0);
    expect(controller.currentChunk, 1);
    expect(controller.currentChunkText, isEmpty);
  });

  test(
    'Restores session and navigates to saved chunk if file exists',
    () async {
      SharedPreferences.setMockInitialValues({
        'last_document_path': samplePdfFile.path,
        'last_document_name': 'test_sample.pdf',
        'last_chunk_index': 2,
      });

      final controller = DocumentReaderController();

      // Allow async _restoreLastSession to complete
      await Future.delayed(const Duration(milliseconds: 200));

      expect(controller.documentFileName, 'test_sample.pdf');
      expect(controller.totalChunks, 3);
      expect(controller.currentChunk, 2);
      expect(controller.currentChunkText, contains('Page Two'));
    },
  );

  test(
    'Falls back to empty state and clears prefs if saved file does not exist',
    () async {
      SharedPreferences.setMockInitialValues({
        'last_document_path': '${tempDir.path}/non_existent_file.pdf',
        'last_document_name': 'non_existent_file.pdf',
        'last_chunk_index': 2,
      });

      final controller = DocumentReaderController();

      // Allow async _restoreLastSession to complete
      await Future.delayed(const Duration(milliseconds: 200));

      expect(controller.documentFileName, isNull);
      expect(controller.totalChunks, 0);
      expect(controller.currentChunk, 1);

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('last_document_path'), isNull);
      expect(prefs.getInt('last_chunk_index'), isNull);
    },
  );

  test('Updating chunk saves new chunk index to SharedPreferences', () async {
    SharedPreferences.setMockInitialValues({
      'last_document_path': samplePdfFile.path,
      'last_document_name': 'test_sample.pdf',
      'last_chunk_index': 1,
    });

    final controller = DocumentReaderController();
    await Future.delayed(const Duration(milliseconds: 200));

    expect(controller.currentChunk, 1);

    await controller.setChunk(3);
    expect(controller.currentChunk, 3);
    expect(controller.currentChunkText, contains('Page Three'));

    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getInt('last_chunk_index'), 3);
  });

  test('Restores speech rate and language from SharedPreferences', () async {
    SharedPreferences.setMockInitialValues({
      'narration_speed': 1.5,
      'narration_language': 'en-GB',
    });

    final controller = DocumentReaderController();
    await Future.delayed(const Duration(milliseconds: 50));

    expect(controller.speechRate, 1.5);
    expect(controller.speechLanguage, 'en-GB');
  });

  test(
    'updateSpeechSettings updates state and persists to SharedPreferences',
    () async {
      SharedPreferences.setMockInitialValues({});
      final controller = DocumentReaderController();
      await Future.delayed(const Duration(milliseconds: 50));

      expect(controller.speechRate, 1.0);
      expect(controller.speechLanguage, isNull);

      await controller.updateSpeechSettings(
        speechRate: 1.25,
        language: 'es-ES',
      );

      expect(controller.speechRate, 1.25);
      expect(controller.speechLanguage, 'es-ES');

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getDouble('narration_speed'), 1.25);
      expect(prefs.getString('narration_language'), 'es-ES');
    },
  );
}
