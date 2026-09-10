## Why

Currently, `DocumentReaderController` overloads a single boolean `isLoading` for both full document initialization and individual page/chunk navigation. As a result:
1. Flipping pages in `PlayerView` sets `isLoading = true`, which kicks the user out to the full-screen `LoadingView` spinner and causes jarring visual flickering.
2. On Android, selecting files from cloud storage (e.g. Google Drive) delays setting the loading state until after the file is downloaded to device cache, leaving the user with no visual feedback during the download phase.
3. Concurrent file picker actions are not prevented while a document is actively being loaded.

## What Changes

- Introduce a dedicated document loading status in `DocumentReaderController` distinct from page/chunk extraction.
- Display `LoadingView` only during full document loading (on application launch session restoration and during file selection/download).
- Ensure page navigation within `PlayerView` is immediate, seamless, and never unmounts `PlayerView` or shows `LoadingView`.
- Trigger document loading status immediately when the user selects a file (handling Android SAF cloud downloads).
- Disable "Select another file" / "Select PDF or EPUB file" actions while a document is loading to prevent concurrent load operations.

## Capabilities

### Modified Capabilities
- `document-loading`: Refine document loading requirements to restrict `LoadingView` strictly to full document lifecycle events, ensure immediate zero-latency page transitions in `PlayerView`, activate loading state immediately on file selection (including cloud downloads), and disable file picker triggers during active document loading.

## Impact

- `lib/controllers/document_reader_controller.dart`: Introduce dedicated status / loading flags, update `pickFile`, `_restoreLastSession`, `_loadDocument`, and `setChunk`.
- `lib/screens/document_reader_screen.dart`: Route to `LoadingView` strictly on dedicated document loading status.
- `lib/screens/player_view.dart` & `lib/screens/empty_state_view.dart`: Disable file selection buttons while a document is loading.
- Tests in `test/` verifying page navigation without full-screen loading transitions and correct document loading state progression.
