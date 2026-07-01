import 'package:uuid/uuid.dart';

import '../models/product.dart';
import '../models/product_category.dart';
import '../models/product_unit.dart';

class ProductCsvImportService {
  ProductCsvImportService._();

  static CsvImportPreview preview({
    required String rawCsv,
    required List<Product> existingProducts,
  }) {
    final lines = rawCsv
        .split(RegExp(r'\r?\n'))
        .map((line) => line.trim())
        .where((line) => line.isNotEmpty)
        .toList();

    if (lines.isEmpty) {
      return const CsvImportPreview(
        rows: [],
        generalError: 'Cole o conteúdo do CSV para importar.',
      );
    }

    final delimiter = _detectDelimiter(lines.first);
    final header = _splitLine(lines.first, delimiter)
        .map(_normalizeHeader)
        .toList();

    final indexes = _HeaderIndexes.fromHeader(header);

    if (!indexes.hasRequiredFields) {
      return CsvImportPreview(
        rows: const [],
        generalError:
            'Cabeçalho inválido. Use: codigo;nome;categoria;unidade;preco;estoque;minimo;custo',
      );
    }

    final existingCodes = existingProducts
        .where((product) => !product.isDeleted)
        .map((product) => _normalizeCode(product.code))
        .toSet();

    final csvCodes = <String>{};
    final rows = <CsvImportRow>[];

    for (var i = 1; i < lines.length; i++) {
      final columns = _splitLine(lines[i], delimiter);
      final lineNumber = i + 1;

      final code = _get(columns, indexes.code).trim();
      final name = _get(columns, indexes.name).trim();
      final categoryText = _get(columns, indexes.category).trim();
      final unitText = _get(columns, indexes.unit).trim();
      final priceText = _get(columns, indexes.price).trim();
      final stockText = _get(columns, indexes.stock).trim();
      final minStockText = _get(columns, indexes.minStock).trim();
      final costText = indexes.cost == null ? '0' : _get(columns, indexes.cost!).trim();

      final errors = <String>[];

      if (code.isEmpty) errors.add('Código vazio.');
      if (name.isEmpty) errors.add('Nome vazio.');

      final normalizedCode = _normalizeCode(code);

      if (normalizedCode.isNotEmpty && existingCodes.contains(normalizedCode)) {
        errors.add('Código já existe no estoque.');
      }

      if (normalizedCode.isNotEmpty && csvCodes.contains(normalizedCode)) {
        errors.add('Código repetido no próprio CSV.');
      }

      final category = _parseCategory(categoryText);
      if (category == null) {
        errors.add('Categoria inválida: "$categoryText".');
      }

      final unit = _parseUnit(unitText);
      if (unit == null) {
        errors.add('Unidade inválida: "$unitText".');
      }

      final price = _parseMoney(priceText);
      if (price <= 0) {
        errors.add('Preço precisa ser maior que zero.');
      }

      final stock = _parseNumber(stockText);
      if (stock < 0) {
        errors.add('Estoque não pode ser negativo.');
      }

      final minStock = _parseNumber(minStockText);
      if (minStock < 0) {
        errors.add('Mínimo não pode ser negativo.');
      }

      final cost = _parseMoney(costText);
      if (cost < 0) {
        errors.add('Custo não pode ser negativo.');
      }

      if (normalizedCode.isNotEmpty) {
        csvCodes.add(normalizedCode);
      }

      Product? product;

      if (errors.isEmpty) {
        final now = DateTime.now();

        product = Product(
          id: const Uuid().v4(),
          code: code,
          name: name,
          category: category!,
          unit: unit!,
          salePrice: price,
          costPrice: cost,
          stockQuantity: stock,
          minStock: minStock,
          favorite: false,
          createdAt: now,
          updatedAt: now,
        );
      }

      rows.add(
        CsvImportRow(
          lineNumber: lineNumber,
          code: code,
          name: name,
          categoryText: categoryText,
          unitText: unitText,
          priceText: priceText,
          stockText: stockText,
          minStockText: minStockText,
          costText: costText,
          product: product,
          errors: errors,
        ),
      );
    }

    return CsvImportPreview(rows: rows);
  }

  static String sampleCsv() {
    return [
      'codigo;nome;categoria;unidade;preco;estoque;minimo;custo',
      '1001;Picanha;bovina;kg;69,90;20;5;45,00',
      '1002;Frango inteiro;frango;kg;14,90;30;5;9,00',
      '1003;Carvão;carvao;pacote;12,00;15;3;0',
    ].join('\n');
  }

  static String acceptedCategoriesText() {
    return ProductCategory.values
        .map((category) => '${category.name} (${category.label})')
        .join(', ');
  }

  static String acceptedUnitsText() {
    return ProductUnit.values
        .map((unit) => '${unit.name} (${unit.label})')
        .join(', ');
  }

  static String _detectDelimiter(String line) {
    if (line.contains(';')) return ';';
    if (line.contains('\t')) return '\t';
    return ',';
  }

  static List<String> _splitLine(String line, String delimiter) {
    final result = <String>[];
    final buffer = StringBuffer();
    var insideQuotes = false;

    for (var i = 0; i < line.length; i++) {
      final char = line[i];

      if (char == '"') {
        insideQuotes = !insideQuotes;
        continue;
      }

      if (char == delimiter && !insideQuotes) {
        result.add(buffer.toString().trim());
        buffer.clear();
        continue;
      }

      buffer.write(char);
    }

    result.add(buffer.toString().trim());

    return result;
  }

  static String _get(List<String> columns, int index) {
    if (index < 0 || index >= columns.length) return '';

    return columns[index];
  }

  static String _normalizeHeader(String value) {
    final normalized = _normalizeText(value)
        .replaceAll('_', ' ')
        .replaceAll('-', ' ')
        .replaceAll(RegExp(r'\\s+'), ' ')
        .trim();

    switch (normalized) {
      case 'cod':
      case 'codigo':
      case 'code':
        return 'codigo';

      case 'nome':
      case 'name':
      case 'produto':
        return 'nome';

      case 'categoria':
      case 'category':
        return 'categoria';

      case 'unidade':
      case 'unit':
        return 'unidade';

      case 'preco':
      case 'preco venda':
      case 'valor':
      case 'saleprice':
      case 'sale price':
        return 'preco';

      case 'estoque':
      case 'qtd':
      case 'quantidade':
      case 'stock':
        return 'estoque';

      case 'min':
      case 'minimo':
      case 'estoque minimo':
      case 'minstock':
      case 'min stock':
        return 'minimo';

      case 'custo':
      case 'cost':
      case 'costprice':
      case 'cost price':
        return 'custo';

      default:
        return normalized;
    }
  }

  static String _normalizeText(String value) {
    return value
        .toLowerCase()
        .trim()
        .replaceAll('á', 'a')
        .replaceAll('à', 'a')
        .replaceAll('ã', 'a')
        .replaceAll('â', 'a')
        .replaceAll('é', 'e')
        .replaceAll('ê', 'e')
        .replaceAll('í', 'i')
        .replaceAll('ó', 'o')
        .replaceAll('ô', 'o')
        .replaceAll('õ', 'o')
        .replaceAll('ú', 'u')
        .replaceAll('ç', 'c');
  }

  static String _normalizeCode(String value) {
    final digits = value.replaceAll(RegExp(r'[^0-9]'), '');
    final parsed = int.tryParse(digits);

    if (parsed == null) return digits;

    return parsed.toString();
  }

  static ProductCategory? _parseCategory(String value) {
    final normalized = _normalizeText(value);

    if (normalized.isEmpty) return null;

    for (final category in ProductCategory.values) {
      if (_normalizeText(category.name) == normalized ||
          _normalizeText(category.label) == normalized) {
        return category;
      }
    }

    return null;
  }

  static ProductUnit? _parseUnit(String value) {
    final normalized = _normalizeText(value);

    if (normalized.isEmpty) return null;

    for (final unit in ProductUnit.values) {
      if (_normalizeText(unit.name) == normalized ||
          _normalizeText(unit.label) == normalized) {
        return unit;
      }
    }

    return null;
  }

  static double _parseMoney(String value) {
    return _parseNumber(value.replaceAll('R\$', '').trim());
  }

  static double _parseNumber(String value) {
    final cleaned = value
        .trim()
        .replaceAll('.', '')
        .replaceAll(',', '.')
        .replaceAll(RegExp(r'[^0-9\.\-]'), '');

    return double.tryParse(cleaned) ?? -1;
  }
}

class CsvImportPreview {
  const CsvImportPreview({
    required this.rows,
    this.generalError,
  });

  final List<CsvImportRow> rows;
  final String? generalError;

  List<CsvImportRow> get validRows {
    return rows.where((row) => row.isValid).toList();
  }

  List<CsvImportRow> get invalidRows {
    return rows.where((row) => !row.isValid).toList();
  }

  bool get canImport {
    return generalError == null && validRows.isNotEmpty;
  }
}

class CsvImportRow {
  const CsvImportRow({
    required this.lineNumber,
    required this.code,
    required this.name,
    required this.categoryText,
    required this.unitText,
    required this.priceText,
    required this.stockText,
    required this.minStockText,
    required this.costText,
    required this.product,
    required this.errors,
  });

  final int lineNumber;
  final String code;
  final String name;
  final String categoryText;
  final String unitText;
  final String priceText;
  final String stockText;
  final String minStockText;
  final String costText;
  final Product? product;
  final List<String> errors;

  bool get isValid => product != null && errors.isEmpty;
}

class _HeaderIndexes {
  const _HeaderIndexes({
    required this.code,
    required this.name,
    required this.category,
    required this.unit,
    required this.price,
    required this.stock,
    required this.minStock,
    required this.cost,
  });

  final int code;
  final int name;
  final int category;
  final int unit;
  final int price;
  final int stock;
  final int minStock;
  final int? cost;

  bool get hasRequiredFields {
    return code >= 0 &&
        name >= 0 &&
        category >= 0 &&
        unit >= 0 &&
        price >= 0 &&
        stock >= 0 &&
        minStock >= 0;
  }

  factory _HeaderIndexes.fromHeader(List<String> header) {
    return _HeaderIndexes(
      code: _indexOfAny(header, ['codigo', 'code']),
      name: _indexOfAny(header, ['nome', 'name', 'produto']),
      category: _indexOfAny(header, ['categoria', 'category']),
      unit: _indexOfAny(header, ['unidade', 'unit']),
      price: _indexOfAny(header, ['preco', 'saleprice', 'sale_price']),
      stock: _indexOfAny(header, ['estoque', 'stock']),
      minStock: _indexOfAny(header, ['minimo', 'minstock', 'min_stock']),
      cost: _nullableIndexOfAny(header, ['custo', 'cost', 'costprice', 'cost_price']),
    );
  }

  static int _indexOfAny(List<String> header, List<String> names) {
    final index = _nullableIndexOfAny(header, names);

    return index ?? -1;
  }

  static int? _nullableIndexOfAny(List<String> header, List<String> names) {
    for (final name in names) {
      final index = header.indexOf(name);
      if (index >= 0) return index;
    }

    return null;
  }
}
