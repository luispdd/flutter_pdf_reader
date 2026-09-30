## 1. Background Isolate Parsing

- [x] 1.1 Refactor `EpubReaderService` to execute book parsing, HTML cleaning, and chunk splitting in `Isolate.run` and verify with `flutter test test/epub_reader_service_test.dart`
- [x] 1.2 Ensure `DocumentReaderController._loadDocument()` yields to the event loop prior to heavy document processing so the loading screen mounts immediately

## 2. Dedicated LoadingView Component

- [x] 2.1 Create `lib/screens/loading_view.dart` featuring a continuously rotating icon animated via `AnimationController` and `RotationTransition`, styled with amber theme accents, glowing container, document title, and loading status label
- [x] 2.2 Add unit/widget tests in `test/loading_view_test.dart` verifying that `LoadingView` renders the animated spinning icon, file title, and status message

## 3. Launch State & View Routing

- [x] 3.1 Update `DocumentReaderController` to accept optional `SharedPreferences? prefs`, synchronously resolve whether a saved file exists on launch to initialize `_isLoading` and `_documentFileName`, and keep asynchronous fallback when `prefs` is omitted
- [x] 3.2 Update `lib/main.dart` to preload `SharedPreferences.getInstance()` prior to `runApp` and forward `prefs` into `DocumentReaderController`
- [x] 3.3 Update `DocumentReaderScreen` in `lib/screens/document_reader_screen.dart` to cleanly switch between `LoadingView` (when `isLoading`), `EmptyStateView` (when `totalChunks == 0`), and `PlayerView` (when chunks exist)
- [x] 3.4 Remove the legacy embedded `SizedBox` progress indicator from `PlayerView` in `lib/screens/player_view.dart`

## 4. Cancellable Loading & Cancel Button

- [x] 4.1 Add an `onCancel` callback and a styled "Cancel" button to `LoadingView` in `lib/screens/loading_view.dart`
- [x] 4.2 Implement `cancelLoading()` with load generation tokens in `DocumentReaderController` to allow cancelling boot restoration and new document selection, clearing state back to `EmptyStateView`
- [x] 4.3 Wire `onCancel: () => controller.cancelLoading()` in `DocumentReaderScreen`
- [x] 4.4 Add unit/widget tests for the Cancel button in `test/loading_view_test.dart` and cancellation behavior in `test/document_reader_controller_test.dart`

## 5. Developer & Coding Agent Guidance

- [x] 5.1 Create `AGENTS.md` containing repository architecture, directory breakdown, essential development commands, and agent gotchas (repeating animations in tests, isolate boundaries, load generation tokens)
- [x] 5.2 Update `README.md` with comprehensive features, quick start guide, architectural overview, and a link to `AGENTS.md`
