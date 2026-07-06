import '../models/product.dart';
import '../models/product_unit.dart';

enum balançaExportFormat {
  pluCsvHeader,
  pluCsvNoHeader,
  pluTxtTab,
  simpleCsv,
  priceOnlyCsv,
}

extension balançaExportFormatLabel on balançaExportFormat {
  String get label {
    switch (this) {
      case balançaExportFormat.pluCsvHeader:
        return 'PLU completo CSV com cabeçalho';
      case balançaExportFormat.pluCsvNoHeader:
        return 'PLU completo CSV sem cabeçalho';
      case balançaExportFormat.pluTxtTab:
        return 'PLU completo TXT por TAB';
      case balançaExportFormat.simpleCsv:
        return 'CSV simples código/nome/preço';
      case balançaExportFormat.priceOnlyCsv:
        return 'CSV mínimo PLU/preço';
    }
  }

  String get fileName {
    switch (this) {
      case balançaExportFormat.pluCsvHeader:
        return 'ramuza_plu_completo_com_cabecalho.csv';
      case balançaExportFormat.pluCsvNoHeader:
        return 'ramuza_plu_completo_sem_cabecalho.csv';
      case balançaExportFormat.pluTxtTab:
        return 'ramuza_plu_completo_tab.txt';
      case balançaExportFormat.simpleCsv:
        return 'ramuza_simples_codigo_nome_preco.csv';
      case balançaExportFormat.priceOnlyCsv:
        return 'ramuza_minimo_plu_preco.csv';
    }
  }

  String get description {
    switch (this) {
      case balançaExportFormat.pluCsvHeader:
        return 'Formato principal para importar no software da balança via Excel/CSV, com campos de PLU, nome, tipo, preço, código, validade e setor.';
      case balançaExportFormat.pluCsvNoHeader:
        return 'Mesmo formato principal, mas sem cabeçalho. Use se o importador não aceitar a primeira linha.';
      case balançaExportFormat.pluTxtTab:
        return 'Mesmo formato principal separado por TAB para testar em Carregar TXT.';
      case balançaExportFormat.simpleCsv:
        return 'Formato simples para teste manual: código, nome, unidade, preço e validade.';
      case balançaExportFormat.priceOnlyCsv:
        return 'Formato mínimo para importadores que pedem só PLU, descrição e preço.';
    }
  }
}

class balançaExportFile {
  const balançaExportFile({
    required this.format,
    required this.fileName,
    required this.content,
  });

  final balançaExportFormat format;
  final String fileName;
  final String content;
}

class balançaExportValidation {
  const balançaExportValidation({required this.errors, required this.warnings});

  final List<String> errors;
  final List<String> warnings;

  bool get hasErrors => errors.isNotEmpty;
  bool get hasWarnings => warnings.isNotEmpty;
}

class balançaExportService {
  balançaExportService._();

  static balançaExportValidation validateProducts(List<Product> products) {
    final errors = <String>[];
    final warnings = <String>[];
    final seenCodes = <String, String>{};

    if (products.isEmpty) {
      errors.add('Selecione pelo menos um produto para exportar.');
    }

    for (final product in products) {
      final code = _digitsOnly(product.code);

      if (product.name.trim().isEmpty) {
        errors.add('Produto sem nome encontrado.');
      }

      if (code.isEmpty) {
        errors.add('${product.name}: código interno/PLU vazio.');
      }

      if (product.salePrice <= 0) {
        errors.add(
          '${product.name}: preço de venda precisa ser maior que zero.',
        );
      }

      if (code.length > 6) {
        warnings.add(
          '${product.name}: código/PLU com mais de 6 dígitos. A balança pode não aceitar.',
        );
      }

      if (code.length > 4) {
        warnings.add(
          '${product.name}: o leitor padrão está configurado para 4 dígitos de PLU. Ajuste em "Configurar leitura" se a balança imprimir mais dígitos.',
        );
      }

      if (product.name.length > 40) {
        warnings.add('${product.name}: nome será cortado para 40 caracteres.');
      }

      if (product.unit != ProductUnit.kg) {
        warnings.add(
          '${product.name}: produto não está em kg. Será exportado como peça.',
        );
      }

      if (seenCodes.containsKey(code)) {
        errors.add(
          'Código duplicado: $code usado em "${seenCodes[code]}" e "${product.name}".',
        );
      } else {
        seenCodes[code] = product.name;
      }
    }

    return balançaExportValidation(errors: errors, warnings: warnings);
  }

  static balançaExportFile buildFile({
    required List<Product> products,
    required balançaExportFormat format,
    required int validityDays,
    required bool removeAccents,
  }) {
    final content = switch (format) {
      balançaExportFormat.pluCsvHeader => _buildPluFile(
        products: products,
        validityDays: validityDays,
        removeAccents: removeAccents,
        includeHeader: true,
        separator: ';',
      ),
      balançaExportFormat.pluCsvNoHeader => _buildPluFile(
        products: products,
        validityDays: validityDays,
        removeAccents: removeAccents,
        includeHeader: false,
        separator: ';',
      ),
      balançaExportFormat.pluTxtTab => _buildPluFile(
        products: products,
        validityDays: validityDays,
        removeAccents: removeAccents,
        includeHeader: false,
        separator: '\t',
      ),
      balançaExportFormat.simpleCsv => _buildSimpleCsv(
        products: products,
        validityDays: validityDays,
        removeAccents: removeAccents,
      ),
      balançaExportFormat.priceOnlyCsv => _buildPriceOnlyCsv(
        products: products,
        removeAccents: removeAccents,
      ),
    };

    return balançaExportFile(
      format: format,
      fileName: format.fileName,
      content: content,
    );
  }

  static List<balançaExportFile> buildAllFiles({
    required List<Product> products,
    required int validityDays,
    required bool removeAccents,
  }) {
    return balançaExportFormat.values.map((format) {
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

1. Abra o software da balança no Windows.
2. Faça backup antes de importar qualquer arquivo.
3. Use Arquivo > Importar/Exportar > Excel/CSV ou Carregar TXT.
4. Teste primeiro: ramuza_plu_completo_com_cabecalho.csv.
5. Se o software não aceitar cabeçalho, teste: ramuza_plu_completo_sem_cabecalho.csv.
6. Se ainda não aceitar, teste: ramuza_plu_completo_tab.txt.
7. Depois de importar os PLUs, envie para a balança pelo próprio software da balança.
8. Imprima uma etiqueta de teste.
9. Leia a etiqueta no PDV do Açougue do Leleco.
10. Se a etiqueta sair com outro padrão de código, ajuste em "Configurar leitura".

PADRÃO PREPARADO NO APP

Código interno do produto = PLU.
Produtos em kg = Peso.
Produtos em unidade/pacote = Peca.
Decimal de preço = vírgula.
Separador CSV = ponto e vírgula.

OBSERVAÇÃO

O manual mostra que o software da balança trabalha com importação/exportação por TMS, Excel/CSV e TXT.
O formato TMS parece ser backup próprio do software, então o app gera CSV/TXT para importação segura.
'''
        .trim();
  }

  static String _buildPluFile({
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
          'NumeroPLU',
          'Nome',
          'Tipo',
          'PrecoUnitario',
          'CodigoProduto',
          'EAN13Fornecedor',
          'ValidadeDias',
          'Setor',
          'SubSetor',
          'Lote',
          'DataImpressao',
        ].join(separator),
      );
    }

    for (var index = 0; index < products.length; index++) {
      final product = products[index];
      final plu = _pluNumber(product, index);

      buffer.writeln(
        [
          plu,
          _cleanText(product.name, removeAccents: removeAccents, max: 40),
          _scaleUnit(product.unit),
          _formatMoney(product.salePrice),
          _digitsOnly(product.code),
          '',
          validityDays.toString(),
          '1',
          '1',
          '0',
          'Pesagem',
        ].join(separator),
      );
    }

    return buffer.toString().trimRight();
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

    return buffer.toString().trimRight();
  }

  static String _buildPriceOnlyCsv({
    required List<Product> products,
    required bool removeAccents,
  }) {
    final buffer = StringBuffer();

    buffer.writeln('PLU;Descricao;Preco');

    for (final product in products) {
      buffer.writeln(
        [
          _digitsOnly(product.code),
          _cleanText(product.name, removeAccents: removeAccents, max: 40),
          _formatMoney(product.salePrice),
        ].join(';'),
      );
    }

    return buffer.toString().trimRight();
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
      case ProductUnit.unidade:
      case ProductUnit.pacote:
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
