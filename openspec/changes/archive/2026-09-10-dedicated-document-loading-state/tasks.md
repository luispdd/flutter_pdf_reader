## 1. Controller State Refactor

- [x] 1.1 Add `bool _isDocumentLoading` state and `bool get isDocumentLoading` getter in `DocumentReaderController`, setting it during `_restoreLastSession` and `_loadDocument`, and verify via unit tests
- [x] 1.2 Update `pickFile` in `DocumentReaderController` to activate `isDocumentLoading` immediately upon selection and handle cancellation cleanup, and verify via unit tests
- [x] 1.3 Ensure `setChunk` does not set `_isDocumentLoading`, maintaining instant text switching without document loading states, and verify via unit tests

## 2. Screen & UI Integration

- [x] 2.1 Update `DocumentReaderScreen` to show `LoadingView` strictly when `controller.isDocumentLoading` is true
- [x] 2.2 Disable "Select another file" in `PlayerView` and "Select PDF or EPUB file" in `EmptyStateView` while `controller.isDocumentLoading` is true
- [x] 2.3 Verify `PlayerView` remains mounted and updates text immediately across page flips without animation or full-screen loading transitions

## 3. Verification & Testing

- [x] 3.1 Update and add unit/widget tests in `test/document_reader_controller_test.dart` and `test/widget_test.dart` covering document loading states and page navigation
- [x] 3.2 Run `flutter test` and `dart analyze` to ensure all tests pass with zero warnings
