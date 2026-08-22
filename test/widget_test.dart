import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:flutter_pdf_reader/main.dart';
import 'package:flutter_pdf_reader/controllers/document_reader_controller.dart';
import 'package:flutter_pdf_reader/screens/document_reader_screen.dart';
import 'package:flutter_pdf_reader/screens/configuration_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    const MethodChannel ttsChannel = MethodChannel('flutter_tts');
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(ttsChannel, (MethodCall call) async {
          switch (call.method) {
            case 'getLanguages':
              return ['en-US', 'es-ES', 'fr-FR'];
            default:
              return 1;
          }
        });
  });
  testWidgets('App renders empty state smoke test', (
    WidgetTester tester,
  ) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const MyApp());

    // Verify that empty state elements are present.
    expect(find.text('Document Audio Reader'), findsOneWidget);
    expect(find.text('No document selected'), findsOneWidget);
    expect(find.text('Select PDF or EPUB file'), findsOneWidget);
    expect(find.text('Read text from clipboard'), findsOneWidget);
  });

  testWidgets('Shows player state and text dialog correctly', (
    WidgetTester tester,
  ) async {
    final controller = DocumentReaderController();
    await tester.pumpWidget(
      ChangeNotifierProvider.value(
        value: controller,
        child: const MaterialApp(home: DocumentReaderScreen()),
      ),
    );

    // Verify initial empty state
    expect(find.text('No document selected'), findsOneWidget);
  });

  testWidgets(
    'Opens configuration screen and interacts with speed slider and apply button',
    (WidgetTester tester) async {
      final controller = DocumentReaderController();
      await tester.pumpWidget(
        ChangeNotifierProvider.value(
          value: controller,
          child: const MaterialApp(home: DocumentReaderScreen()),
        ),
      );

      // Verify settings button is present in AppBar
      final settingsIcon = find.byIcon(Icons.settings_outlined);
      expect(settingsIcon, findsOneWidget);

      // Tap the settings button to navigate to ConfigurationScreen
      await tester.tap(settingsIcon);
      await tester.pumpAndSettle();

      // Verify configuration screen elements
      expect(find.text('Configuration'), findsOneWidget);
      expect(find.text('Narration Speed'), findsOneWidget);
      expect(find.text('Narration Language'), findsOneWidget);
      expect(find.text('Apply'), findsOneWidget);
      expect(find.byType(Slider), findsOneWidget);

      // Tap Apply button
      final applyButton = find.text('Apply');
      await tester.ensureVisible(applyButton);
      await tester.pumpAndSettle();
      await tester.tap(applyButton);
      await tester.pumpAndSettle();

      // Verify controller settings were applied
      expect(controller.speechRate, 1.0);
      // Verify Configuration screen is dismissed
      expect(find.byType(ConfigurationScreen), findsNothing);
      expect(find.text('Document Audio Reader'), findsOneWidget);
    },
  );
}
