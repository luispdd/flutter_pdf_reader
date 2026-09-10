## Context

See `proposal.md` for motivation and background.

Currently:
1. `DocumentReaderController` initializes with `_isLoading = false` and `_totalChunks = 0`. It initiates `_initSession()` asynchronously without awaiting in constructor.
2. `DocumentReaderScreen` evaluates `totalChunks == 0 && !isLoading` and displays `EmptyStateView` on frame 1.
3. Loading in `PlayerView` is rendered as a conditional 400px height box containing `CircularProgressIndicator`.
4. Document parsing (EPUB unzipping, chapter traversal, HTML stripping via DOM parsing, and paragraph chunking) runs synchronously on the main Dart UI isolate, starving Flutter's animation ticker and causing the progress indicator to freeze.

## Goals / Non-Goals

**Goals:**
- Guarantee immediate rendering of `LoadingView` on launch when a saved document exists on disk, without flashing `EmptyStateView`.
- Guarantee immediate rendering of `EmptyStateView` on launch when no saved document exists.
- Create a dedicated, reusable `LoadingView` widget with an amber theme and a continuously rotating icon.
- Offload CPU-intensive EPUB parsing to a background isolate using `Isolate.run` so the UI isolate never freezes.
- Seamlessly transition from `LoadingView` to `PlayerView` upon load completion.

**Non-Goals:**
- Redesigning the `PlayerView` controls or waveform layout.
- Changing the storage format or keys of `SharedPreferences`.
- Modifying TTS playback engines or Linux Piper subprocess mechanics.

## Decisions

### 1. Preload SharedPreferences before `runApp`

**Decision**: Await `SharedPreferences.getInstance()` in `main()` and pass `SharedPreferences` to `DocumentReaderController({SharedPreferences? prefs, ...})`.
- **Rationale**: By having preferences available at instantiation time, the controller can inspect `last_document_path` and verify file existence synchronously before frame 1 renders.
  - If a valid file exists: `_isLoading` is initialized to `true`, and `_documentFileName` is set immediately. Frame 1 renders `LoadingView`.
  - If no file exists: `_isLoading` is initialized to `false`. Frame 1 renders `EmptyStateView`.
- **Alternatives Considered**:
  - *Show a splash/loading screen on every launch while reading prefs asynchronously*: This causes a perceptible loading flash even when the user has no document.
  - *Keep async restore in constructor without preloading*: Causes `EmptyStateView` to flash before `_loadDocument` is called.

### 2. Dedicated `LoadingView` Widget with Continuous Rotation

**Decision**: Build a standalone widget `LoadingView` in `lib/screens/loading_view.dart`.
- **UI Architecture**:
  - Uses an `AnimationController` repeating indefinitely (`_controller.repeat()`).
  - Wraps a themed icon (such as `Icons.autorenew_rounded` or `Icons.sync_rounded`) in `RotationTransition`.
  - Pairs the rotating icon with an amber glow effect and an outer circular accent/track, styled consistently with `EmptyStateView` and `app_theme.dart`.
  - Displays the document file name (if known) and a contextual status label ("Loading document...", "Preparing pages, please wait...").
- **Alternatives Considered**:
  - *Standard `CircularProgressIndicator` alone*: Does not feel like a custom styled spinning icon and lacks document title context.
  - *Animated GIF / Lottie asset*: Adds unnecessary external dependencies or binary assets; pure Flutter `RotationTransition` is lightweight, vector-sharp, and 60/120 FPS performant.

### 3. Offload Heavy Document Parsing to Background Isolate (`Isolate.run`)

**Decision**: In `EpubReaderService.loadDocument(String path)`, delegate the byte reading, `EpubReader.readBook`, chapter iteration, HTML parsing (`_stripHtml`), and `_smartSplit` to `Isolate.run()`.
- **Rationale**: `TextChunk` models consist of primitive types (`int`, `String`, `String?`) which are passed back seamlessly from `Isolate.run`. By executing this in a worker isolate, the main isolate's event loop is completely unencumbered, allowing the `AnimationController` to tick continuously at 60/120 FPS.
- **Alternatives Considered**:
  - *`Future.delayed(Duration.zero)` periodic yielding*: Still keeps heavy CPU work on the main thread and causes frame drops and jank.
  - *Compute / Isolate on PDF loading*: PDF `pages.count` is fast and page text extraction happens on-demand per page. However, a microtask delay before parsing ensures Flutter has mounted the initial frame of `LoadingView`.

### 4. View Routing in `DocumentReaderScreen`

**Decision**: Structure the view selection in `DocumentReaderScreen.build()` cleanly:
```dart
if (controller.isLoading) {
  return LoadingView(fileName: controller.documentFileName);
}
if (controller.totalChunks == 0) {
  return EmptyStateView(
    onPickFile: () => controller.pickFile(),
    onReadClipboard: () => controller.readClipboard(),
  );
}
return PlayerView(controller: controller);
```
- **Rationale**: Eliminates the conditional hack inside `PlayerView` where a 400px SizedBox with a loader was rendered. Separates loading, empty, and player states into distinct view concerns.

## Risks / Trade-offs

- **[Risk] Preloading `SharedPreferences` in `main()` slows down startup** → `SharedPreferences.getInstance()` on desktop and mobile reads an in-memory cached XML/key-value file, typically completing in < 10ms. This is imperceptible compared to native app launch latency.
- **[Risk] Existing unit tests initialize `DocumentReaderController` without passing `prefs`** → The constructor parameter `prefs` will be optional (`SharedPreferences? prefs`). When `null`, it falls back gracefully to calling `_initSession()` asynchronously, ensuring 100% backward compatibility with all existing tests.
- **[Risk] `Isolate.run` compatibility** → `Isolate.run` is part of core Dart 2.19+ and Flutter 3.7+ across Linux, Android, iOS, Windows, and macOS.
