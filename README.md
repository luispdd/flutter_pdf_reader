# Document Audio Reader (`flutter_pdf_reader`)

A high-performance, distraction-free Flutter document reader that reads your **PDF** and **EPUB** books aloud using text-to-speech (TTS), styled with a sleek dark amber theme.

---

## ✨ Features

- 📖 **Multi-Format Support**:
  - **PDF Documents**: Extracted page by page using `syncfusion_flutter_pdf`.
  - **EPUB E-books**: Full chapter extraction, HTML cleanup, and deduplication via `epubx`.
- ⚡ **Background Isolate Parsing**:
  - Heavy EPUB decompression and HTML chunking are offloaded to Dart background isolates (`Isolate.run`), preventing UI freezes and maintaining silky smooth 60/120 FPS animations.
- ⏳ **Seamless Launch & Loading Screen**:
  - Instant launch state resolution without UI flickering.
  - Dedicated `LoadingView` with a continuously spinning accent icon and informative file status.
  - **Cancellable Loading**: Cancel in-flight document processing at any time during app boot or new file selection to return to the empty state.
- 🗣️ **Text-to-Speech (TTS)**:
  - Adjustable speech speed (0.5x to 2.5x).
  - Multiple language and dialect support.
  - Native fallback TTS on Linux environments.
- 🛡️ **Smart Code Block Filtering**:
  - Option to automatically omit programming code blocks and snippets from EPUB technical books to streamline spoken listening.
- 📋 **Clipboard Audio Reader**:
  - Instantly listen to copied clipboard content on the fly.
- 🔄 **State Persistence**:
  - Remembers your last-opened document and current reading position across app restarts.
- 🎧 **Background Audio Service**:
  - Integrated Android foreground service (`flutter_foreground_task`) keeps audio playback running when the app is minimized.

---

## 🚀 Quick Start

### Prerequisites
- [Flutter SDK](https://docs.flutter.dev/get-started/install) (Dart 3.13+)
- For Linux desktop: standard GTK development libraries (`libgtk-3-dev`, etc.)

### Run Application
```bash
# Get dependencies
flutter pub get

# Run on Linux Desktop
flutter run -d linux

# Run on Android
flutter run -d android
```

### Static Analysis & Verification
```bash
# Run analyzer
dart analyze

# Format code
dart format .
```

---

## 🛠️ Architecture Overview

The app follows a clean, reactive provider-based architecture:

- **`lib/controllers/document_reader_controller.dart`**: Central `ChangeNotifier` state manager orchestrating document loading, playback position, audio controls, settings persistence, and cancellation.
- **`lib/readers/`**: Dedicated document parsers (`PdfReaderService`, `EpubReaderService`, `ClipboardReaderService`) implementing the `ReaderService` contract.
- **`lib/screens/`**:
  - `DocumentReaderScreen`: Master scaffold that dynamically switches between `LoadingView`, `EmptyStateView`, and `PlayerView`.
  - `LoadingView`: Animated loading state with continuous icon rotation and a Cancel button.
  - `PlayerView`: Main reader UI with interactive chunk text, waveform accent, and playback controls.
  - `ConfigurationScreen`: Settings modal for narration rate, language, and code filtering.
- **`lib/core/app_theme.dart`**: Design system tokens (rich amber accent colors, sleek dark surfaces, consistent typography).

For in-depth developer workflows, agent execution rules, and testing gotchas, refer to [AGENTS.md](file:///home/fuchik0ma/code/flutter/flutter_pdf_reader/AGENTS.md).
