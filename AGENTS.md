# AGENTS.md

Developer and Coding Agent guide for **flutter_pdf_reader**.

---

## 1. Project Overview

**flutter_pdf_reader** is a cross-platform Flutter application (optimized for Linux desktop and Android) designed for audio narration of PDF and EPUB documents.

### Key Capabilities:
- **Document Ingestion**: Supports `.pdf` (via `syncfusion_flutter_pdf`) and `.epub` (via `epubx` and `html`).
- **Text Chunking**: Splits document pages/chapters into clean paragraph chunks for speech synthesis.
- **Text-to-Speech (TTS)**: Leverages `flutter_tts` with customizable speech rate, language selection, and fallback Linux TTS process handling.
- **Code Filtering**: Configurable option to filter programming code blocks out of technical EPUB books prior to speech synthesis.
- **Background Isolate Parsing**: Heavy document parsing (EPUB zip decompression, DOM traversal, chunking) is offloaded to background isolates using `Isolate.run` to preserve 60/120 FPS UI animations.
- **Cancellable Loading**: Immediate launch state resolution using preloaded `SharedPreferences`, smooth animated `LoadingView`, and user-cancellable loading during boot or new file selection.
- **Background Narration**: Integrates `flutter_foreground_task` to prevent the OS from killing audio playback when minimized.

---

## 2. Architecture & File Structure

```
lib/
├── core/
│   ├── app_theme.dart               # Global styling, amber palette (kAmber, kBgDark, etc.)
│   └── reader_service.dart          # Base interface: ReaderService & TextChunk model
├── controllers/
│   └── document_reader_controller.dart # Main ChangeNotifier state controller
├── readers/
│   ├── pdf_reader_service.dart      # PDF parsing and page-based chunk extraction
│   ├── epub_reader_service.dart     # EPUB parsing, HTML cleaning, isolate offloading
│   └── clipboard_reader_service.dart# System clipboard text reader
├── screens/
│   ├── document_reader_screen.dart  # Top-level screen; routes Loading, Empty, or Player views
│   ├── loading_view.dart            # Animated spinning icon with Cancel button
│   ├── empty_state_view.dart        # Screen displayed when no document is open
│   ├── player_view.dart             # Playback controls, chunk text display, progress bar
│   ├── clipboard_reader_screen.dart # Full-screen reader for clipboard text
│   └── configuration_screen.dart    # Settings modal (speed, language, code filtering)
├── services/
│   └── foreground_service_manager.dart # Android foreground service integration
└── main.dart                        # Entrypoint with preloaded SharedPreferences
```

---

## 3. Essential Commands

### Static Analysis & Quality Checks
```bash
# Verify code health, imports, and lint warnings (Recommended before finishing tasks)
dart analyze

# Format code across the project
dart format .
```

### Running the App
```bash
# Run on Linux desktop (default target for local development)
flutter run -d linux

# Run on Android (if device/emulator attached)
flutter run -d android
```

### Testing
```bash
# Run a specific unit test file
flutter test test/epub_reader_service_test.dart
flutter test test/loading_view_test.dart
flutter test test/document_reader_controller_test.dart

# Run all tests with a per-test timeout
flutter test --timeout 30s
```

---

## 4. Key Implementation Patterns & Gotchas

### 1. Repeating Animations in Tests
`LoadingView` features a continuous `AnimationController.repeat()` rotation.
- **Gotcha**: Never use `tester.pumpAndSettle()` on screens rendering `LoadingView`. Because the animation repeats indefinitely, `pumpAndSettle()` will time out and cause test commands to hang.
- **Solution**: Use `tester.pump(const Duration(milliseconds: ...))` to advance frames deterministically.

### 2. Document Loading & Cancellation
- The loading lifecycle uses a generation token (`_loadGeneration`) inside `DocumentReaderController`.
- When `_loadDocument()` executes, it checks `_loadGeneration == currentGen` across all async gaps (`await Future.delayed`, `await _activeReader!.loadDocument()`, etc.).
- When the user presses "Cancel" in `LoadingView`, `controller.cancelLoading()` is invoked:
  - Increments `_loadGeneration` to invalidate in-flight async tasks.
  - Clears `_documentPath`, `_documentFileName`, and resets `_isLoading = false` and `_totalChunks = 0`.
  - Clears the saved session from `SharedPreferences` so the app doesn't attempt to reload it on next boot.
  - Drops back directly to `EmptyStateView`.

### 3. Preloaded SharedPreferences
- `main()` awaits `SharedPreferences.getInstance()` before `runApp()`.
- The instance is passed to `DocumentReaderController(prefs: prefs)` to allow synchronous initialization of `_isLoading` on Frame 1.
- In unit tests, `prefs` is optional (`DocumentReaderController({SharedPreferences? prefs})`), ensuring tests can run without full app startup boilerplate.

### 4. Background Isolates (`Isolate.run`)
- All CPU-heavy document parsing in `EpubReaderService` is isolated via `Isolate.run`.
- Models returned across isolate boundaries must be composed of sendable Dart primitives or pure data classes (like `TextChunk(index, text, title)`).

### 5. Hot Reload & DTD
- Antigravity IDE connects to running Flutter apps via the Dart Tooling Daemon (`dtd`).
- If an app is running, hot reloads should be triggered after modifying `lib/` files. If no app is running, proceed normally.
