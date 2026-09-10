## Context

Currently, `DocumentReaderController.isLoading` is set during both full document loading (`_loadDocument`) and chunk navigation (`setChunk`). In `DocumentReaderScreen`, checking `controller.isLoading` unmounts `PlayerView` and displays `LoadingView`. Additionally, `FilePicker.pickFiles` on Android may involve caching/downloading files from cloud providers (e.g. Google Drive) before returning `PlatformFile`, during which no loading state was active.

## Goals / Non-Goals

**Goals:**
- Separate document-level loading from page/chunk extraction so `LoadingView` is only shown when a document file is being initialized/downloaded.
- Keep `PlayerView` mounted and responsive during all chunk navigation with immediate text display.
- Activate document loading immediately when file selection or cloud download begins.
- Disable file selection triggers during active document loading to prevent concurrent load operations.

**Non-Goals:**
- Changing EPUB/PDF text parsing engines or chunking algorithms.
- Adding a cancel button to document loading (as requested).

## Decisions

### Decision 1: Introduce `bool _isDocumentLoading` in `DocumentReaderController`
- **Choice**: Add a dedicated getter `bool get isDocumentLoading` (or `DocumentLoadingStatus`).
- **Rationale**: Keeps the state contract clean and distinct. `_isDocumentLoading` is set to `true` exclusively during `_loadDocument` and active file selection/download.
- **Alternative Considered**: Reusing `isLoading` and removing `setChunk` loading — rejected because `isLoading` was semantically ambiguous and could cause regression in tests or components expecting a generic loading indicator.

### Decision 2: Immediate File Picker Loading Feedback & Callback Hook
- **Choice**: In `pickFile()`, set `_isDocumentLoading = true; notifyListeners();` right away (and pass `onFileLoading` to `FilePicker.platform.pickFiles`). If the user cancels the picker, reset `_isDocumentLoading` back to `false`.
- **Rationale**: On Android, selecting a file from Google Drive triggers the download before `pickFiles()` resolves. Setting the state immediately ensures `LoadingView` is visible while the cloud file is cached locally.

### Decision 3: Update `DocumentReaderScreen` Routing
- **Choice**: Switch `DocumentReaderScreen._buildBody` to check `controller.isDocumentLoading` instead of `controller.isLoading`.
- **Rationale**: `LoadingView` will only render on launch restoration and new document selection. Page navigation within `PlayerView` will never unmount `PlayerView`.

### Decision 4: Disable File Selection Buttons When Loading
- **Choice**: In `PlayerView` ("Select another file") and `EmptyStateView` ("Select PDF or EPUB file"), pass `onPressed: controller.isDocumentLoading ? null : () => controller.pickFile()`.
- **Rationale**: Prevents accidental concurrent file picker launches while a document is being parsed.

## Risks / Trade-offs

- **[Risk]** Picker cancellation leaves `_isDocumentLoading = true` if not handled.
  - **Mitigation**: Wrap `FilePicker.pickFiles` in `try-finally` and ensure cancellation (null/empty result) resets `_isDocumentLoading = false`.
- **[Risk]** Large chunks taking noticeable time to render text.
  - **Mitigation**: Text extraction is from in-memory string chunks, taking < 5ms. Instant replacement without animations delivers optimal responsiveness.
