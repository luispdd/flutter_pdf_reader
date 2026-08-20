class TextChunk {
  final int index;
  final String text;
  final String? label;

  TextChunk({
    required this.index,
    required this.text,
    this.label,
  });
}
