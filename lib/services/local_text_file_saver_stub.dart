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
}) {
  throw UnsupportedError(
    'Salvar arquivo local não disponível nesta plataforma.',
  );
}

Future<List<SavedTextFile>> saveTextFiles(List<GeneratedTextFile> files) {
  throw UnsupportedError(
    'Salvar arquivo local não disponível nesta plataforma.',
  );
}
