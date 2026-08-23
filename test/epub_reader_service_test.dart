import 'dart:io';
import 'package:archive/archive.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_pdf_reader/readers/epub_reader_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory tempDir;

  setUpAll(() async {
    tempDir = await Directory.systemTemp.createTemp('epub_reader_test_');
  });

  tearDownAll(() async {
    if (await tempDir.exists()) {
      await tempDir.delete(recursive: true);
    }
  });

  Future<File> createSampleEpub(String htmlBody) async {
    final archive = Archive();
    const mimetype = 'application/epub+zip';
    archive.addFile(ArchiveFile('mimetype', mimetype.length, mimetype.codeUnits));

    const containerXml = '''<?xml version="1.0"?>
<container version="1.0" xmlns="urn:oasis:names:tc:opendocument:xmlns:container">
  <rootfiles>
    <rootfile full-path="OEBPS/content.opf" media-type="application/oebps-package+xml"/>
  </rootfiles>
</container>''';
    archive.addFile(ArchiveFile(
        'META-INF/container.xml', containerXml.length, containerXml.codeUnits));

    const contentOpf = '''<?xml version="1.0" encoding="utf-8"?>
<package xmlns="http://www.idpf.org/2007/opf" unique-identifier="bookid" version="2.0">
  <metadata xmlns:dc="http://purl.org/dc/elements/1.1/">
    <dc:title>Test Book</dc:title>
    <dc:identifier id="bookid">urn:uuid:12345</dc:identifier>
  </metadata>
  <manifest>
    <item id="chapter1" href="chapter1.html" media-type="application/xhtml+xml"/>
    <item id="ncx" href="toc.ncx" media-type="application/x-dtbncx+xml"/>
  </manifest>
  <spine toc="ncx">
    <itemref idref="chapter1"/>
  </spine>
</package>''';
    archive.addFile(ArchiveFile(
        'OEBPS/content.opf', contentOpf.length, contentOpf.codeUnits));

    const tocNcx = '''<?xml version="1.0" encoding="utf-8"?>
<ncx xmlns="http://www.daisy.org/z3986/2005/ncx/" version="2005-1">
  <head>
    <meta name="dtb:uid" content="urn:uuid:12345"/>
  </head>
  <docTitle><text>Test Book</text></docTitle>
  <navMap>
    <navPoint id="navpoint-1" playOrder="1">
      <navLabel><text>Chapter 1</text></navLabel>
      <content src="chapter1.html"/>
    </navPoint>
  </navMap>
</ncx>''';
    archive.addFile(ArchiveFile('OEBPS/toc.ncx', tocNcx.length, tocNcx.codeUnits));

    final htmlContent = '''<!DOCTYPE html>
<html>
<head><title>Chapter 1</title></head>
<body>
$htmlBody
</body>
</html>''';
    archive.addFile(
        ArchiveFile('OEBPS/chapter1.html', htmlContent.length, htmlContent.codeUnits));

    final zipData = ZipEncoder().encode(archive);
    final file =
        File('${tempDir.path}/test_${DateTime.now().microsecondsSinceEpoch}.epub');
    await file.writeAsBytes(zipData!);
    return file;
  }

  test('EpubReaderService preserves code when filterCode is false', () async {
    const html = '''
<p>Introduction paragraph.</p>
<pre><code>void main() { print("Hello World"); }</code></pre>
<p>Conclusion paragraph.</p>
''';
    final file = await createSampleEpub(html);
    final reader = EpubReaderService(filterCode: false);
    await reader.loadDocument(file.path);

    expect(reader.totalChunks, greaterThan(0));
    final chunkText = await reader.extractTextForChunk(1);
    expect(chunkText, contains('Introduction paragraph.'));
    expect(chunkText, contains('void main()'));
    expect(chunkText, contains('Conclusion paragraph.'));
  });

  test('EpubReaderService skips code blocks and code classes when filterCode is true', () async {
    const html = '''
<p>First paragraph explaining concepts.</p>
<code>int x = 42;</code>
<div class="code">print(x);</div>
<div class="code-block">String name = "test";</div>
<div class="codeblock">bool isTest = true;</div>
<div class="sourceCode"><pre>source code snippet</pre></div>
<div class="source-code">source-code content</div>
<div class="programlisting">programlisting content</div>
<div class="program-listing">program-listing content</div>
<p>Final paragraph summarizing conclusions.</p>
''';
    final file = await createSampleEpub(html);
    final reader = EpubReaderService(filterCode: true);
    await reader.loadDocument(file.path);

    expect(reader.totalChunks, greaterThan(0));
    final chunkText = await reader.extractTextForChunk(1);
    expect(chunkText, contains('First paragraph explaining concepts.'));
    expect(chunkText, contains('Final paragraph summarizing conclusions.'));
    expect(chunkText, isNot(contains('int x = 42;')));
    expect(chunkText, isNot(contains('print(x);')));
    expect(chunkText, isNot(contains('String name = "test";')));
    expect(chunkText, isNot(contains('bool isTest = true;')));
    expect(chunkText, isNot(contains('source code snippet')));
    expect(chunkText, isNot(contains('source-code content')));
    expect(chunkText, isNot(contains('programlisting content')));
    expect(chunkText, isNot(contains('program-listing content')));
  });
}
