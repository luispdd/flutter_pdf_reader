import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'controllers/document_reader_controller.dart';

void main() {
  runApp(
    MultiProvider(
      providers: [ChangeNotifierProvider(create: (_) => DocumentReaderController())],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Document Reader',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.deepPurple,
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
      ),
      themeMode: ThemeMode.dark,
      home: const DocumentReaderScreen(),
    );
  }
}

class DocumentReaderScreen extends StatelessWidget {
  const DocumentReaderScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<DocumentReaderController>();

    final chunkTypeLabel = controller.isEpub ? 'Chunk' : 'Page';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Document Audio Reader'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (controller.documentFileName != null)
              Text(
                'File: ${controller.documentFileName}',
                style: Theme.of(context).textTheme.titleMedium,
                textAlign: TextAlign.center,
              ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: () => controller.pickFile(),
              icon: const Icon(Icons.file_upload),
              label: const Text('Select PDF or Epub File'),
            ),
            const SizedBox(height: 40),
            if (controller.totalChunks > 0) ...[
              Text(
                '$chunkTypeLabel ${controller.currentChunk} of ${controller.totalChunks}',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyLarge,
              ),
              Slider(
                value: controller.currentChunk.toDouble(),
                min: 1,
                max: controller.totalChunks.toDouble(),
                divisions: controller.totalChunks > 1
                    ? controller.totalChunks - 1
                    : 1,
                label: controller.currentChunk.toString(),
                onChanged: (value) {
                  controller.setChunk(value.toInt());
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
                    child: Icon(
                      controller.isPlaying ? Icons.stop : Icons.play_arrow,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              OutlinedButton.icon(
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: Text('$chunkTypeLabel ${controller.currentChunk} Text'),
                      content: SingleChildScrollView(
                        child: Text(
                          controller.currentChunkText.isEmpty
                              ? "No text found on this $chunkTypeLabel."
                              : controller.currentChunkText,
                        ),
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
                label: Text('Show $chunkTypeLabel Text'),
              ),
            ],
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: () {
                if (controller.isReadingClipboard) {
                  controller.stopClipboardNarration();
                } else {
                  controller.readClipboard();
                }
              },
              icon: Icon(
                controller.isReadingClipboard
                    ? Icons.stop
                    : Icons.content_paste,
              ),
              label: Text(
                controller.isReadingClipboard
                    ? 'Stop clipboard playback'
                    : 'Read text from Clipboard',
              ),
            ),
          ],
        ),
      ),
    );
  }
}
