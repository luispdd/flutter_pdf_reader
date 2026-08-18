import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'pdf_reader_controller.dart';

void main() {
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => PdfReaderController()),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'PDF Reader',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.deepPurple,
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
      ),
      themeMode: ThemeMode.dark,
      home: const PdfReaderScreen(),
    );
  }
}

class PdfReaderScreen extends StatelessWidget {
  const PdfReaderScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<PdfReaderController>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('PDF Audio Reader'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (controller.pdfFileName != null)
              Text(
                'File: ${controller.pdfFileName}',
                style: Theme.of(context).textTheme.titleMedium,
                textAlign: TextAlign.center,
              ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: () => controller.pickFile(),
              icon: const Icon(Icons.file_upload),
              label: const Text('Select PDF File'),
            ),
            const SizedBox(height: 40),
            if (controller.totalPages > 0) ...[
              Text(
                'Page ${controller.currentPage} of ${controller.totalPages}',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyLarge,
              ),
              Slider(
                value: controller.currentPage.toDouble(),
                min: 1,
                max: controller.totalPages.toDouble(),
                divisions: controller.totalPages > 1 ? controller.totalPages - 1 : 1,
                label: controller.currentPage.toString(),
                onChanged: (value) {
                  controller.setPage(value.toInt());
                },
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  FloatingActionButton(
                    onPressed: () {
                      if (controller.isPlaying) {
                        controller.stopNarration();
                      } else {
                        controller.startNarration();
                      }
                    },
                    child: Icon(controller.isPlaying ? Icons.stop : Icons.play_arrow),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              OutlinedButton.icon(
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: Text('Page ${controller.currentPage} Text'),
                      content: SingleChildScrollView(
                        child: Text(controller.currentPageText.isEmpty ? "No text found on this page." : controller.currentPageText),
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text('Close'),
                        ),
                      ],
                    ),
                  );
                },
                icon: const Icon(Icons.text_snippet),
                label: const Text('Show Page Text'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
