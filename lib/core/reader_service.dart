abstract class ReaderService {
  /// Loads a document from the given path.
  Future<void> loadDocument(String path);

  /// Total number of chunks or pages.
  int get totalChunks;

  /// Extracts text for a given chunk index (1-based).
  Future<String> extractTextForChunk(int index);

  /// Disposes any resources held by the service.
  void dispose();
}
