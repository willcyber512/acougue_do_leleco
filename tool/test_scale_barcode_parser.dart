import '../lib/models/scale_barcode_data.dart';
import '../lib/services/scales/scale_barcode_parser.dart';

void main() {
  const parser = ScaleBarcodeParser();

  print('==============================');
  print('TESTE: PARSER DE ETIQUETA');
  print('==============================');

  final generated = parser.buildInternalScaleCode(
    productCode: '1234',
    valueInCentsOrGrams: 1587,
  );

  print('Codigo gerado: $generated');

  final parsed = parser.parse(
    generated,
    mode: ScaleBarcodeMode.priceEmbedded,
  );

  if (parsed == null) {
    print('ERRO: codigo nao foi interpretado');
    return;
  }

  print('Codigo bruto: ${parsed.rawCode}');
  print('Produto: ${parsed.productCode}');
  print('Valor interno: ${parsed.valueCode}');
  print('Digito correto: ${parsed.isCheckDigitValid}');
  print('Modo: ${parsed.modeLabel}');
  print('Preco interpretado: R\$ ${parsed.priceFromBarcode.toStringAsFixed(2)}');
}
