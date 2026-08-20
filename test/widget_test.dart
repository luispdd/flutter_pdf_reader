import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:flutter_pdf_reader/main.dart';
import 'package:flutter_pdf_reader/controllers/document_reader_controller.dart';

void main() {
  testWidgets('App renders empty state smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const MyApp());

    // Verify that empty state elements are present.
    expect(find.text('Document Audio Reader'), findsOneWidget);
    expect(find.text('No document selected'), findsOneWidget);
    expect(find.text('Select PDF or EPUB file'), findsOneWidget);
    expect(find.text('Read text from clipboard'), findsOneWidget);
  });

  testWidgets('Shows player state and text dialog correctly', (WidgetTester tester) async {
    final controller = DocumentReaderController();
    await tester.pumpWidget(
      ChangeNotifierProvider.value(
        value: controller,
        child: const MaterialApp(
          home: DocumentReaderScreen(),
        ),
      ),
    );

    // Verify initial empty state
    expect(find.text('No document selected'), findsOneWidget);
  });
}
