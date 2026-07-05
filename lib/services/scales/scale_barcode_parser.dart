import '../../models/scale_barcode_data.dart';

class ScaleBarcodeParser {
  const ScaleBarcodeParser();

  ScaleBarcodeData? parse(
    String input, {
    ScaleBarcodeMode mode = ScaleBarcodeMode.priceEmbedded,
  }) {
    final cleanCode = input.replaceAll(RegExp(r'[^0-9]'), '');

    if (cleanCode.length != 13) {
      return null;
    }

    if (!cleanCode.startsWith('2')) {
      return null;
    }

    final productCode = cleanCode.substring(1, 7);
    final valueCode = cleanCode.substring(7, 12);
    final checkDigit = cleanCode.substring(12, 13);

    return ScaleBarcodeData(
      rawCode: cleanCode,
      productCode: productCode,
      valueCode: valueCode,
      checkDigit: checkDigit,
      isCheckDigitValid: _isEan13CheckDigitValid(cleanCode),
      mode: mode,
    );
  }

  bool _isEan13CheckDigitValid(String code) {
    if (code.length != 13) return false;

    final expected = _calculateEan13CheckDigit(code.substring(0, 12));
    final actual = int.tryParse(code.substring(12, 13));

    return actual != null && expected == actual;
  }

  int _calculateEan13CheckDigit(String first12Digits) {
    if (first12Digits.length != 12) {
      throw ArgumentError('EAN-13 precisa de 12 dígitos para calcular o dígito verificador.');
    }

    var sum = 0;

    for (var i = 0; i < first12Digits.length; i++) {
      final digit = int.parse(first12Digits[i]);
      final weight = i.isEven ? 1 : 3;
      sum += digit * weight;
    }

    final mod = sum % 10;
    return mod == 0 ? 0 : 10 - mod;
  }

  String buildInternalScaleCode({
    required String productCode,
    required int valueInCentsOrGrams,
  }) {
    final cleanProductCode = productCode.replaceAll(RegExp(r'[^0-9]'), '');
    final cleanProduct = cleanProductCode.padLeft(6, '0').substring(0, 6);
    final cleanValue = valueInCentsOrGrams.toString().padLeft(5, '0').substring(0, 5);

    final first12 = '2$cleanProduct$cleanValue';
    final digit = _calculateEan13CheckDigit(first12);

    return '$first12$digit';
  }
}
