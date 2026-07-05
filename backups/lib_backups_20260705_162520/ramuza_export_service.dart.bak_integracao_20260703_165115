import '../models/product.dart';
import '../models/product_unit.dart';

enum RamuzaExportFormat {
  pluCsvHeader,
  pluCsvNoHeader,
  pluTxtTab,
  simpleCsv,
  priceOnlyCsv,
}

extension RamuzaExportFormatLabel on RamuzaExportFormat {
  String get label {
    switch (this) {
      case RamuzaExportFormat.pluCsvHeader:
        return 'PLU completo CSV com cabeçalho';
      case RamuzaExportFormat.pluCsvNoHeader:
        return 'PLU completo CSV sem cabeçalho';
      case RamuzaExportFormat.pluTxtTab:
        return 'PLU completo TXT por TAB';
      case RamuzaExportFormat.simpleCsv:
        return 'CSV simples código/nome/preço';
      case RamuzaExportFormat.priceOnlyCsv:
        return 'CSV básico preço';
    }
  }

  String get fileName {
    switch (this) {
      case RamuzaExportFormat.pluCsvHeader:
        return 'ramuza_plu_completo_com_cabecalho.csv';
      case RamuzaExportFormat.pluCsvNoHeader:
        return 'ramuza_plu_completo_sem_cabecalho.csv';
      case RamuzaExportFormat.pluTxtTab:
        return 'ramuza_plu_completo_tab.txt';
      case RamuzaExportFormat.simpleCsv:
        return 'ramuza_simples_codigo_nome_preco.csv';
      case RamuzaExportFormat.priceOnlyCsv:
        return 'ramuza_basico_preco.csv';
    }
  }

  String get description {
    switch (this) {
      case RamuzaExportFormat.pluCsvHeader:
        return 'Tenta seguir a estrutura de PLU com colunas: Número, Nome, Unidade, Preço, Código, Endereço, Imprimir data de e Validade.';
      case RamuzaExportFormat.pluCsvNoHeader:
        return 'Mesmo formato completo, mas sem a primeira linha de cabeçalho.';
      case RamuzaExportFormat.pluTxtTab:
        return 'Mesmo formato completo, mas separado por TAB. Alguns importadores aceitam melhor TXT/tabulado.';
      case RamuzaExportFormat.simpleCsv:
        return 'Formato simples para testar importação manual: código, nome, unidade, preço e validade.';
      case RamuzaExportFormat.priceOnlyCsv:
        return 'Formato mínimo com código, nome e preço.';
    }
  }
}

class RamuzaExportFile {
  const RamuzaExportFile({
    required this.format,
    required this.fileName,
    required this.content,
  });

  final RamuzaExportFormat format;
  final String fileName;
  final String content;
}

class RamuzaExportValidation {
  const RamuzaExportValidation({
    required this.errors,
    required this.warnings,
  });

  final List<String> errors;
  final List<String> warnings;

  bool get hasErrors => errors.isNotEmpty;
  bool get hasWarnings => warnings.isNotEmpty;
}

class RamuzaExportService {
  RamuzaExportService._();

  static RamuzaExportValidation validateProducts(List<Product> products) {
    final errors = <String>[];
    final warnings = <String>[];
    final seenCodes = <String, String>{};

    for (final product in products) {
      final code = _digitsOnly(product.code);

      if (product.name.trim().isEmpty) {
        errors.add('Produto sem nome encontrado.');
      }

      if (code.isEmpty) {
        errors.add('${product.name}: código interno/PLU vazio.');
      }

      if (product.salePrice <= 0) {
        errors.add('${product.name}: preço de venda precisa ser maior que zero.');
      }

      if (code.length > 6) {
        warnings.add('${product.name}: código/PLU com mais de 6 dígitos. A balança pode não aceitar.');
      }

      if (product.name.length > 40) {
        warnings.add('${product.name}: nome será cortado para 40 caracteres.');
      }

      if (seenCodes.containsKey(code)) {
        errors.add(
          'Código duplicado: $code usado em "${seenCodes[code]}" e "${product.name}".',
        );
      } else {
        seenCodes[code] = product.name;
      }
    }

    return RamuzaExportValidation(
      errors: errors,
      warnings: warnings,
    );
  }

  static RamuzaExportFile buildFile({
    required List<Product> products,
    required RamuzaExportFormat format,
    required int validityDays,
    required bool removeAccents,
  }) {
    final content = switch (format) {
      RamuzaExportFormat.pluCsvHeader => _buildPluCsv(
          products: products,
          validityDays: validityDays,
          removeAccents: removeAccents,
          includeHeader: true,
          separator: ';',
        ),
      RamuzaExportFormat.pluCsvNoHeader => _buildPluCsv(
          products: products,
          validityDays: validityDays,
          removeAccents: removeAccents,
          includeHeader: false,
          separator: ';',
        ),
      RamuzaExportFormat.pluTxtTab => _buildPluCsv(
          products: products,
          validityDays: validityDays,
          removeAccents: removeAccents,
          includeHeader: false,
          separator: '\t',
        ),
      RamuzaExportFormat.simpleCsv => _buildSimpleCsv(
          products: products,
          validityDays: validityDays,
          removeAccents: removeAccents,
        ),
      RamuzaExportFormat.priceOnlyCsv => _buildPriceOnlyCsv(
          products: products,
          removeAccents: removeAccents,
        ),
    };

    return RamuzaExportFile(
      format: format,
      fileName: format.fileName,
      content: content,
    );
  }

  static List<RamuzaExportFile> buildAllFiles({
    required List<Product> products,
    required int validityDays,
    required bool removeAccents,
  }) {
    return RamuzaExportFormat.values.map((format) {
      return buildFile(
        products: products,
        format: format,
        validityDays: validityDays,
        removeAccents: removeAccents,
      );
    }).toList();
  }

  static String buildPackage({
    required List<Product> products,
    required int validityDays,
    required bool removeAccents,
  }) {
    final files = buildAllFiles(
      products: products,
      validityDays: validityDays,
      removeAccents: removeAccents,
    );

    final buffer = StringBuffer();

    buffer.writeln('PACOTE DE EXPORTAÇÃO RAMUZA - AÇOUGUE DO LELECO');
    buffer.writeln('Produtos: ${products.length}');
    buffer.writeln('Validade padrão: $validityDays dia(s)');
    buffer.writeln('');
    buffer.writeln(buildInstructions());
    buffer.writeln('');

    for (final file in files) {
      buffer.writeln('==================================================');
      buffer.writeln('ARQUIVO: ${file.fileName}');
      buffer.writeln('FORMATO: ${file.format.label}');
      buffer.writeln('DESCRIÇÃO: ${file.format.description}');
      buffer.writeln('==================================================');
      buffer.writeln(file.content);
      buffer.writeln('');
    }

    return buffer.toString();
  }

  static String buildInstructions() {
    return '''
INSTRUÇÕES DE TESTE NO SOFTWARE RAMUZA

1. Abra o software da Ramuza no Windows.
2. Faça backup antes de importar qualquer arquivo.
3. Procure a área de PLU/produtos.
4. Teste primeiro o formato "PLU completo CSV com cabeçalho".
5. Se não importar, teste o formato "PLU completo CSV sem cabeçalho".
6. Se ainda não funcionar, teste o TXT por TAB.
7. Depois de importar, envie os PLUs para a balança pelo próprio software Ramuza.
8. Imprima uma etiqueta de teste e leia no PDV do sistema.

Observação:
Este gerador prepara os dados em vários layouts. A confirmação final depende do importador do software oficial da Ramuza instalado no Windows.
'''.trim();
  }

  static String _buildPluCsv({
    required List<Product> products,
    required int validityDays,
    required bool removeAccents,
    required bool includeHeader,
    required String separator,
  }) {
    final buffer = StringBuffer();

    if (includeHeader) {
      buffer.writeln(
        [
          'Número',
          'Nome',
          'Unidade',
          'Preço',
          'Código',
          'Endereço',
          'Imprimir data de',
          'Validade',
        ].join(separator),
      );
    }

    for (var index = 0; index < products.length; index++) {
      final product = products[index];

      buffer.writeln(
        [
          _pluNumber(product, index),
          _cleanText(product.name, removeAccents: removeAccents, max: 40),
          _scaleUnit(product.unit),
          _formatMoney(product.salePrice),
          _digitsOnly(product.code),
          _pluNumber(product, index),
          'Pesagem',
          validityDays.toString(),
        ].join(separator),
      );
    }

    return buffer.toString().trim();
  }

  static String _buildSimpleCsv({
    required List<Product> products,
    required int validityDays,
    required bool removeAccents,
  }) {
    final buffer = StringBuffer();

    buffer.writeln('Codigo;Nome;Unidade;Preco;Validade');

    for (final product in products) {
      buffer.writeln(
        [
          _digitsOnly(product.code),
          _cleanText(product.name, removeAccents: removeAccents, max: 40),
          _scaleUnit(product.unit),
          _formatMoney(product.salePrice),
          validityDays.toString(),
        ].join(';'),
      );
    }

    return buffer.toString().trim();
  }

  static String _buildPriceOnlyCsv({
    required List<Product> products,
    required bool removeAccents,
  }) {
    final buffer = StringBuffer();

    buffer.writeln('Codigo;Nome;Preco');

    for (final product in products) {
      buffer.writeln(
        [
          _digitsOnly(product.code),
          _cleanText(product.name, removeAccents: removeAccents, max: 40),
          _formatMoney(product.salePrice),
        ].join(';'),
      );
    }

    return buffer.toString().trim();
  }

  static String _pluNumber(Product product, int index) {
    final code = _digitsOnly(product.code);
    final parsed = int.tryParse(code);

    if (parsed != null && parsed > 0) {
      return parsed.toString();
    }

    return (index + 1).toString();
  }

  static String _scaleUnit(ProductUnit unit) {
    switch (unit) {
      case ProductUnit.kg:
        return 'Peso';
      default:
        return 'Peca';
    }
  }

  static String _formatMoney(double value) {
    return value.toStringAsFixed(2).replaceAll('.', ',');
  }

  static String _digitsOnly(String value) {
    return value.replaceAll(RegExp(r'[^0-9]'), '');
  }

  static String _cleanText(
    String value, {
    required bool removeAccents,
    required int max,
  }) {
    var text = value.trim();

    if (removeAccents) {
      text = _removeAccents(text);
    }

    text = text
        .replaceAll(';', ' ')
        .replaceAll('\t', ' ')
        .replaceAll('\n', ' ')
        .replaceAll('\r', ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .toUpperCase();

    if (text.length > max) {
      text = text.substring(0, max);
    }

    return text;
  }

  static String _removeAccents(String value) {
    const from = 'ÁÀÂÃÄÉÈÊËÍÌÎÏÓÒÔÕÖÚÙÛÜÇÑáàâãäéèêëíìîïóòôõöúùûüçñ';
    const to = 'AAAAAEEEEIIIIOOOOOUUUUCNaaaaaeeeeiiiiooooouuuucn';

    var result = value;

    for (var i = 0; i < from.length; i++) {
      result = result.replaceAll(from[i], to[i]);
    }

    return result;
  }
}
