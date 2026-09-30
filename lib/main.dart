import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:flutter_pdf_reader/core/app_theme.dart';
import 'package:flutter_pdf_reader/screens/document_reader_screen.dart';
import 'package:flutter_pdf_reader/controllers/document_reader_controller.dart';
import 'package:flutter_pdf_reader/services/foreground_service_manager.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  ForegroundServiceManager.init();
  final prefs = await SharedPreferences.getInstance();
  runApp(MyApp(prefs: prefs));
}

class MyApp extends StatelessWidget {
  final SharedPreferences? prefs;
  final DocumentReaderController? controller;

  const MyApp({super.key, this.prefs, this.controller});

  @override
  Widget build(BuildContext context) {
    final app = MaterialApp(
      title: 'Document Reader',
      debugShowCheckedModeBanner: false,
      themeMode: ThemeMode.dark,
      theme: buildAppTheme(),
      home: const DocumentReaderScreen(),
    );

    if (controller != null) {
      return ChangeNotifierProvider.value(
        value: controller!,
        child: app,
      );
    }

    return ChangeNotifierProvider(
      create: (_) => DocumentReaderController(prefs: prefs),
      child: app,
    );
  }
}
