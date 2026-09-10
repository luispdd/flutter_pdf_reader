## Why

When the application launches and a previously opened document exists, there is a perceptible delay while session data is read and the document is parsed. During this window, the UI briefly flashes the `EmptyStateView` ("No document selected") before transitioning to the reader. Furthermore, the existing loading state does not feature an animated spinning indicator—the UI isolate is blocked during synchronous parsing, freezing any progress indicator in place.

This change introduces a dedicated document loading screen with a continuously rotating icon, prevents the empty state flash on launch when restoring a file, shows `EmptyStateView` immediately on launch when there is no saved file, and offloads heavy document parsing from the UI isolate so that the loading indicator spins smoothly without stutter or freeze.

## What Changes

- **Dedicated Loading Screen**: Replace the embedded 400px progress indicator in `PlayerView` with a dedicated `LoadingView` component displaying a continuously rotating icon, document name, and loading status message.
- **Immediate State on Launch**:
  - If a saved document exists in persistent storage, the application launches directly into the loading screen without showing `EmptyStateView`.
  - If no saved document exists, the application immediately displays `EmptyStateView` on launch.
- **Continuously Rotating Icon**: Implement an animated, continuously spinning icon for the loading screen that rotates smoothly at 60/120 FPS.
- **Offload Document Parsing**: Move heavy parsing (such as EPUB unzipping, HTML DOM parsing, and chunk generation) to a background isolate (`Isolate.run`), preventing UI isolate saturation and ensuring animations remain fluid.
- **Consistent File Selection Flow**: When the user selects a new document via `pickFile()`, the application transitions immediately to `LoadingView` while the new file is parsed in the background.

## Capabilities

### New Capabilities
- `document-loading`: Covers the loading lifecycle, initial launch state resolution (restoring vs empty), dedicated loading screen display with continuously rotating icon, and background isolate processing.

### Modified Capabilities
<!-- None, as there are no existing specs in the project. -->

## Impact

- **UI Components**:
  - New `LoadingView` widget in `lib/screens/loading_view.dart`.
  - Updated `DocumentReaderScreen` in `lib/screens/document_reader_screen.dart` to cleanly switch between `LoadingView`, `EmptyStateView`, and `PlayerView`.
  - Cleaned up `PlayerView` in `lib/screens/player_view.dart` to remove the embedded `c.isLoading && c.totalChunks == 0` loading container.
- **Controllers & Services**:
  - Updated `DocumentReaderController` in `lib/controllers/document_reader_controller.dart` to support synchronous initial state resolution via preloaded `SharedPreferences` and handle loading states properly.
  - Updated `main.dart` to preload `SharedPreferences` before `runApp`.
  - Updated `EpubReaderService` in `lib/readers/epub_reader_service.dart` to parse chapters in a background isolate (`Isolate.run`).
- **Tests**:
  - Added widget tests for `LoadingView` and initial startup states.
