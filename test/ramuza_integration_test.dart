import 'package:flutter_test/flutter_test.dart';

import 'package:acougue_do_leleco/models/product.dart';
import 'package:acougue_do_leleco/models/product_category.dart';
import 'package:acougue_do_leleco/models/product_unit.dart';
import 'package:acougue_do_leleco/models/ramuza_barcode_settings.dart';
import 'package:acougue_do_leleco/services/ramuza_barcode_parser.dart';
import 'package:acougue_do_leleco/services/ramuza_export_service.dart';

void main() {
  group('Integração Ramuza/leitor USB', () {
    test('gera e interpreta etiqueta de peso', () {
      final settings = RamuzaBarcodeSettings.defaults();

      final code = RamuzaBarcodeParser.buildTestBarcode(
        productCode: '1001',
        value: 0.750,
        settings: settings,
      );

      expect(code.length, settings.expectedLength);
      expect(code.startsWith('20'), isTrue);

      final parsed = RamuzaBarcodeParser.tryParse(code, settings);

      expect(parsed, isNotNull);
      expect(parsed!.productCode, '1001');
      expect(parsed.quantity, closeTo(0.750, 0.0001));
      expect(parsed.totalPrice, isNull);
      expect(parsed.checksumValid, isTrue);
    });

    test('gera e interpreta etiqueta de valor total', () {
      final settings = RamuzaBarcodeSettings.defaults().copyWith(
        valueMode: RamuzaBarcodeValueMode.totalPrice,
      );

      final code = RamuzaBarcodeParser.buildTestBarcode(
        productCode: '1002',
        value: 25.90,
        settings: settings,
      );

      expect(code.length, settings.expectedLength);

      final parsed = RamuzaBarcodeParser.tryParse(code, settings);

      expect(parsed, isNotNull);
      expect(parsed!.productCode, '1002');
      expect(parsed.totalPrice, closeTo(25.90, 0.001));
      expect(parsed.quantity, isNull);
      expect(parsed.checksumValid, isTrue);
    });

    test('calcula quantidade quando etiqueta vem por valor total', () {
      final product = _product(code: '1002', name: 'Coxão mole', price: 10.00);

      final settings = RamuzaBarcodeSettings.defaults().copyWith(
        valueMode: RamuzaBarcodeValueMode.totalPrice,
      );

      final code = RamuzaBarcodeParser.buildTestBarcode(
        productCode: '1002',
        value: 25.00,
        settings: settings,
      );

      final parsed = RamuzaBarcodeParser.tryParse(code, settings);

      expect(parsed, isNotNull);
      expect(parsed!.quantityForProduct(product), closeTo(2.5, 0.0001));
    });

    test('rejeita código com tamanho errado', () {
      final settings = RamuzaBarcodeSettings.defaults();

      final parsed = RamuzaBarcodeParser.tryParse('12345', settings);

      expect(parsed, isNull);
    });

    test('validação bloqueia preço zero e código duplicado', () {
      final products = [
        _product(code: '1001', name: 'Picanha', price: 69.90),
        _product(code: '1001', name: 'Picanha duplicada', price: 0),
      ];

      final validation = RamuzaExportService.validateProducts(products);

      expect(validation.hasErrors, isTrue);
      expect(validation.errors.join('\n'), contains('preço'));
      expect(validation.errors.join('\n'), contains('duplicado'));
    });

    test('exporta todos os formatos esperados', () {
      final products = [
        _product(code: '1001', name: 'Picanha', price: 69.90),
        _product(code: '2001', name: 'Frango inteiro', price: 13.99),
      ];

      final files = RamuzaExportService.buildAllFiles(
        products: products,
        validityDays: 3,
        removeAccents: true,
      );

      expect(files.length, RamuzaExportFormat.values.length);
      expect(
        files.map((file) => file.fileName),
        contains('ramuza_plu_completo_com_cabecalho.csv'),
      );
      expect(
        files.map((file) => file.fileName),
        contains('ramuza_plu_completo_sem_cabecalho.csv'),
      );
      expect(
        files.map((file) => file.fileName),
        contains('ramuza_plu_completo_tab.txt'),
      );

      for (final file in files) {
        expect(file.content, contains('PICANHA'));
        expect(file.content, contains('69,90'));
      }
    });
  });
}

Product _product({
  required String code,
  required String name,
  required double price,
}) {
  final now = DateTime(2026, 1, 1);

  return Product(
    id: '$code-$name',
    code: code,
    name: name,
    category: ProductCategory.bovina,
    unit: ProductUnit.kg,
    salePrice: price,
    costPrice: price * 0.7,
    stockQuantity: 10,
    minStock: 1,
    favorite: false,
    createdAt: now,
    updatedAt: now,
  );
}
