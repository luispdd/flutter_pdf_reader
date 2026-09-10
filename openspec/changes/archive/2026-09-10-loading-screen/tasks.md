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

## 4. Integration Verification

- [x] 4.1 Update and expand `test/document_reader_controller_test.dart` and `test/widget_test.dart` to verify launch states (immediate `EmptyStateView` when no file exists, immediate `LoadingView` when a saved file exists, and `LoadingView` during `pickFile`)
- [x] 4.2 Run `flutter test` and `dart analyze` to verify all tests pass and no lint or analysis issues exist
