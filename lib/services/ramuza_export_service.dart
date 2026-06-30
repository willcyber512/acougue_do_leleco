import '../models/product.dart';
import '../models/product_unit.dart';

class RamuzaExportService {
  RamuzaExportService._();

  static String buildCsv({
    required List<Product> products,
    required int validityDays,
    required bool includeHeader,
    required bool removeAccents,
  }) {
    final buffer = StringBuffer();

    // Layout baseado na tela de PLU do manual:
    // Número | Nome | Unidade | Preço | Código | Endereço | Imprimir data de | Validade
    if (includeHeader) {
      buffer.writeln(
        [
          'Numero',
          'Nome',
          'Unidade',
          'Preco',
          'Codigo',
          'Endereco',
          'Imprimir data de',
          'Validade',
        ].join(';'),
      );
    }

    for (var index = 0; index < products.length; index++) {
      final product = products[index];

      final row = [
        _pluNumber(product, index),
        _productName(product.name, removeAccents: removeAccents),
        _scaleUnit(product.unit),
        _formatPrice(product.salePrice),
        product.code.trim(),
        '',
        'Imprimir',
        validityDays.toString(),
      ];

      buffer.writeln(row.map(_csvValue).join(';'));
    }

    return buffer.toString();
  }

  static String buildTxt({
    required List<Product> products,
    required int validityDays,
    required bool includeHeader,
    required bool removeAccents,
  }) {
    return buildCsv(
      products: products,
      validityDays: validityDays,
      includeHeader: includeHeader,
      removeAccents: removeAccents,
    );
  }

  static String buildInstructions() {
    return '''
Como testar no software da Ramuza:

1. Primeiro teste com apenas 1 produto.
2. No app, selecione 1 produto e copie o CSV.
3. Salve como produtos_ramuza.csv.
4. No software da Ramuza, tente importar em Excel/CSV arquivo.
5. Depois vá em Base de dados > PLU e confira se apareceu.
6. Se não aparecer, teste novamente desmarcando "Incluir cabeçalho".
7. Se ainda não aparecer, cadastre 1 produto manualmente no software da Ramuza e exporte ele em CSV/TXT. Mande esse arquivo para ajustar o formato exato.

Layout atual gerado:
Numero;Nome;Unidade;Preco;Codigo;Endereco;Imprimir data de;Validade
''';
  }

  static String _pluNumber(Product product, int index) {
    final digitsOnly = product.code.replaceAll(RegExp(r'[^0-9]'), '');
    final parsed = int.tryParse(digitsOnly);

    if (parsed != null && parsed > 0 && parsed <= 999999) {
      return parsed.toString();
    }

    return (index + 1).toString();
  }

  static String _productName(
    String value, {
    required bool removeAccents,
  }) {
    var text = value.trim();

    if (removeAccents) {
      text = _removeAccents(text);
    }

    text = text.replaceAll(';', ' ').replaceAll('\n', ' ');

    if (text.length > 40) {
      text = text.substring(0, 40);
    }

    return text;
  }

  static String _scaleUnit(ProductUnit unit) {
    if (unit == ProductUnit.kg) {
      return 'Peso';
    }

    return 'Peça';
  }

  static String _formatPrice(double value) {
    return value.toStringAsFixed(2).replaceAll('.', ',');
  }

  static String _csvValue(String value) {
    final needsQuotes = value.contains(';') ||
        value.contains('"') ||
        value.contains('\n') ||
        value.contains('\r');

    if (!needsQuotes) {
      return value;
    }

    return '"${value.replaceAll('"', '""')}"';
  }

  static String _removeAccents(String value) {
    const from = 'áàãâäÁÀÃÂÄéèêëÉÈÊËíìîïÍÌÎÏóòõôöÓÒÕÔÖúùûüÚÙÛÜçÇñÑ';
    const to = 'aaaaaAAAAAeeeeEEEEiiiiIIIIoooooOOOOOuuuuUUUUcCnN';

    var result = value;

    for (var i = 0; i < from.length; i++) {
      result = result.replaceAll(from[i], to[i]);
    }

    return result;
  }
}
