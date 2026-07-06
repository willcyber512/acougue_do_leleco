import 'dart:convert';
import 'dart:io';

class GeneratedTextFile {
  const GeneratedTextFile({required this.fileName, required this.content});

  final String fileName;
  final String content;
}

class SavedTextFile {
  const SavedTextFile({required this.fileName, required this.path});

  final String fileName;
  final String path;
}

Future<SavedTextFile> saveTextFile({
  required String fileName,
  required String content,
}) async {
  final folder = await _exportFolder();
  await folder.create(recursive: true);

  final safeName = _safeFileName(fileName);
  final file = File('${folder.path}${Platform.pathSeparator}$safeName');

  await file.writeAsString(content, encoding: utf8, flush: true);

  return SavedTextFile(fileName: safeName, path: file.path);
}

Future<List<SavedTextFile>> saveTextFiles(List<GeneratedTextFile> files) async {
  final saved = <SavedTextFile>[];

  for (final file in files) {
    saved.add(
      await saveTextFile(fileName: file.fileName, content: file.content),
    );
  }

  return saved;
}

Future<Directory> _exportFolder() async {
  final separator = Platform.pathSeparator;

  final home =
      Platform.environment['USERPROFILE'] ??
      Platform.environment['HOME'] ??
      Directory.current.path;

  final downloads = Directory('$home${separator}Downloads');

  final base = downloads.existsSync() ? downloads.path : Directory.current.path;

  return Directory('$base${separator}Açougue do Leleco${separator}balança');
}

String _safeFileName(String value) {
  final cleaned = value
      .replaceAll(RegExp(r'[\\/:*?"<>|]'), '_')
      .replaceAll(RegExp(r'\s+'), '_')
      .trim();

  return cleaned.isEmpty ? 'arquivo_ramuza.txt' : cleaned;
}
