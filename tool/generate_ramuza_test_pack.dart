import 'dart:convert';
import 'dart:io';

import 'package:acougue_do_leleco/models/product.dart';
import 'package:acougue_do_leleco/models/product_category.dart';
import 'package:acougue_do_leleco/models/product_unit.dart';
import 'package:acougue_do_leleco/services/ramuza_export_service.dart';

void main() {
  final products = _products();

  final validation = RamuzaExportService.validateProducts(products);

  final outDir = Directory('ramuza_pacote_teste');

  if (!outDir.existsSync()) {
    outDir.createSync(recursive: true);
  }

  final readme = File('${outDir.path}/LEIA-ME-RAMUZA.txt');

  readme.writeAsStringSync(
    RamuzaExportService.buildInstructions(),
    encoding: utf8,
  );

  final files = RamuzaExportService.buildAllFiles(
    products: products,
    validityDays: 3,
    removeAccents: true,
  );

  for (final file in files) {
    final out = File('${outDir.path}/${file.fileName}');
    out.writeAsStringSync(file.content, encoding: utf8);
  }

  final report = File('${outDir.path}/RELATORIO_VALIDACAO.txt');

  final buffer = StringBuffer();

  buffer.writeln('RELATÓRIO DE VALIDAÇÃO RAMUZA');
  buffer.writeln('Produtos: ${products.length}');
  buffer.writeln('Erros: ${validation.errors.length}');
  buffer.writeln('Avisos: ${validation.warnings.length}');
  buffer.writeln('');

  if (validation.errors.isEmpty) {
    buffer.writeln('ERROS: nenhum');
  } else {
    buffer.writeln('ERROS:');
    for (final error in validation.errors) {
      buffer.writeln('- $error');
    }
  }

  buffer.writeln('');

  if (validation.warnings.isEmpty) {
    buffer.writeln('AVISOS: nenhum');
  } else {
    buffer.writeln('AVISOS:');
    for (final warning in validation.warnings) {
      buffer.writeln('- $warning');
    }
  }

  buffer.writeln('');
  buffer.writeln('ARQUIVOS GERADOS:');

  for (final file in files) {
    buffer.writeln('- ${file.fileName} (${file.format.label})');
  }

  report.writeAsStringSync(buffer.toString(), encoding: utf8);

  stdout.writeln('');
  stdout.writeln('Pacote Ramuza gerado com sucesso.');
  stdout.writeln('Pasta: ${outDir.absolute.path}');
  stdout.writeln('');
  stdout.writeln('Arquivos:');

  for (final file in files) {
    stdout.writeln('- ${file.fileName}');
  }

  stdout.writeln('- LEIA-ME-RAMUZA.txt');
  stdout.writeln('- RELATORIO_VALIDACAO.txt');
  stdout.writeln('');
}

List<Product> _products() {
  final now = DateTime(2026, 1, 1);

  return [
    Product(
      id: '1',
      code: '1001',
      name: 'Picanha',
      category: ProductCategory.bovina,
      unit: ProductUnit.kg,
      salePrice: 69.90,
      costPrice: 52.00,
      stockQuantity: 18.5,
      minStock: 5,
      favorite: true,
      createdAt: now,
      updatedAt: now,
    ),
    Product(
      id: '2',
      code: '1002',
      name: 'Coxão mole',
      category: ProductCategory.bovina,
      unit: ProductUnit.kg,
      salePrice: 39.90,
      costPrice: 29.00,
      stockQuantity: 12,
      minStock: 5,
      favorite: false,
      createdAt: now,
      updatedAt: now,
    ),
    Product(
      id: '3',
      code: '2001',
      name: 'Frango inteiro',
      category: ProductCategory.frango,
      unit: ProductUnit.kg,
      salePrice: 13.99,
      costPrice: 9.50,
      stockQuantity: 25,
      minStock: 8,
      favorite: true,
      createdAt: now,
      updatedAt: now,
    ),
    Product(
      id: '4',
      code: '5001',
      name: 'Carvão 3kg',
      category: ProductCategory.carvao,
      unit: ProductUnit.pacote,
      salePrice: 15.00,
      costPrice: 10.00,
      stockQuantity: 30,
      minStock: 10,
      favorite: false,
      createdAt: now,
      updatedAt: now,
    ),
  ];
}
