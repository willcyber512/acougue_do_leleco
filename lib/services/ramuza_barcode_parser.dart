import '../models/product.dart';
import '../models/product_unit.dart';
import '../models/ramuza_barcode_settings.dart';

class RamuzaParsedBarcode {
  const RamuzaParsedBarcode({
    required this.raw,
    required this.digits,
    required this.productCode,
    required this.valueRaw,
    required this.mode,
    this.quantity,
    this.totalPrice,
    this.checksumDigit,
    this.checksumExpected,
    this.checksumValid,
  });

  final String raw;
  final String digits;
  final String productCode;
  final String valueRaw;
  final RamuzaBarcodeValueMode mode;
  final double? quantity;
  final double? totalPrice;
  final String? checksumDigit;
  final String? checksumExpected;
  final bool? checksumValid;

  double? quantityForProduct(Product product) {
    if (quantity != null) return quantity;

    if (totalPrice == null || product.salePrice <= 0) {
      return null;
    }

    return totalPrice! / product.salePrice;
  }

  String descriptionForProduct(Product product) {
    if (mode == RamuzaBarcodeValueMode.weight) {
      return '${_formatNumber(quantity ?? 0)} ${product.unit.label}';
    }

    return '${_formatMoney(totalPrice ?? 0)} total';
  }

  static String _formatMoney(double value) {
    final fixed = value.toStringAsFixed(2).replaceAll('.', ',');
    return 'R\$ $fixed';
  }

  static String _formatNumber(double value) {
    if (value % 1 == 0) return value.toStringAsFixed(0);
    return value.toStringAsFixed(3).replaceAll('.', ',');
  }
}

class RamuzaBarcodeParser {
  RamuzaBarcodeParser._();

  static RamuzaParsedBarcode? tryParse(
    String input,
    RamuzaBarcodeSettings settings,
  ) {
    if (!settings.enabled) return null;

    final raw = input.trim();
    final digits = raw.replaceAll(RegExp(r'[^0-9]'), '');

    if (digits.isEmpty) return null;
    if (digits.length != settings.expectedLength) return null;

    if (settings.prefix.isNotEmpty && !digits.startsWith(settings.prefix)) {
      return null;
    }

    final prefixEnd = settings.prefix.length;
    final productEnd = prefixEnd + settings.productCodeDigits;
    final valueEnd = productEnd + settings.valueDigits;

    if (digits.length < valueEnd) return null;

    final productCode = digits.substring(prefixEnd, productEnd);
    final valueRaw = digits.substring(productEnd, valueEnd);
    final valueInt = int.tryParse(valueRaw);

    if (valueInt == null) return null;

    String? checksumDigit;
    String? checksumExpected;
    bool? checksumValid;

    if (settings.hasChecksum) {
      checksumDigit = digits.substring(digits.length - 1);
      checksumExpected = calculateChecksum(
        digits.substring(0, digits.length - 1),
      );
      checksumValid = checksumDigit == checksumExpected;
    }

    if (settings.valueMode == RamuzaBarcodeValueMode.weight) {
      return RamuzaParsedBarcode(
        raw: raw,
        digits: digits,
        productCode: productCode,
        valueRaw: valueRaw,
        mode: settings.valueMode,
        quantity: _applyDecimals(valueInt, settings.weightDecimals),
        checksumDigit: checksumDigit,
        checksumExpected: checksumExpected,
        checksumValid: checksumValid,
      );
    }

    return RamuzaParsedBarcode(
      raw: raw,
      digits: digits,
      productCode: productCode,
      valueRaw: valueRaw,
      mode: settings.valueMode,
      totalPrice: _applyDecimals(valueInt, settings.priceDecimals),
      checksumDigit: checksumDigit,
      checksumExpected: checksumExpected,
      checksumValid: checksumValid,
    );
  }

  static String explain(String input, RamuzaBarcodeSettings settings) {
    final raw = input.trim();
    final digits = raw.replaceAll(RegExp(r'[^0-9]'), '');

    if (digits.isEmpty) {
      return 'Digite ou leia um código para testar.';
    }

    if (!settings.enabled) {
      return 'Leitura de etiqueta balança está desativada.';
    }

    if (digits.length != settings.expectedLength) {
      return 'Tamanho inválido. Esperado: ${settings.expectedLength} dígitos. Recebido: ${digits.length}.';
    }

    if (settings.prefix.isNotEmpty && !digits.startsWith(settings.prefix)) {
      return 'Prefixo diferente. Esperado começar com "${settings.prefix}".';
    }

    final parsed = tryParse(input, settings);

    if (parsed == null) {
      return 'Não foi possível interpretar o código.';
    }

    final buffer = StringBuffer();

    buffer.writeln('Produto/PLU: ${parsed.productCode}');

    if (parsed.mode == RamuzaBarcodeValueMode.weight) {
      buffer.writeln('Peso/Qtd: ${_formatNumber(parsed.quantity ?? 0)}');
    } else {
      buffer.writeln('Valor total: ${_formatMoney(parsed.totalPrice ?? 0)}');
    }

    if (settings.hasChecksum) {
      final ok = parsed.checksumValid == true;
      buffer.writeln(
        'Checksum: ${ok ? 'OK' : 'diferente'}'
        '${ok ? '' : ' - não bloqueado para evitar incompatibilidade com etiqueta customizada.'}',
      );
    }

    return buffer.toString().trim();
  }

  static String buildTestBarcode({
    required String productCode,
    required double value,
    required RamuzaBarcodeSettings settings,
  }) {
    final productDigits = settings.productCodeDigits <= 0
        ? 4
        : settings.productCodeDigits;

    final valueDigits = settings.valueDigits <= 0 ? 6 : settings.valueDigits;

    final cleanProduct = _fixedDigits(
      productCode.replaceAll(RegExp(r'[^0-9]'), ''),
      productDigits,
    );

    final decimals = settings.valueMode == RamuzaBarcodeValueMode.weight
        ? settings.weightDecimals
        : settings.priceDecimals;

    final cleanValue = _scaledValue(
      value: value,
      decimals: decimals,
      digits: valueDigits,
    );

    final body = '${settings.prefix}$cleanProduct$cleanValue';

    if (!settings.hasChecksum) {
      return body;
    }

    return '$body${calculateChecksum(body)}';
  }

  static String buildTestBarcodeForProduct({
    required Product product,
    required RamuzaBarcodeSettings settings,
    double quantity = 0.750,
    double totalPrice = 10.00,
  }) {
    final value = settings.valueMode == RamuzaBarcodeValueMode.weight
        ? quantity
        : totalPrice;

    return buildTestBarcode(
      productCode: product.code,
      value: value,
      settings: settings,
    );
  }

  static String calculateChecksum(String body) {
    final digits = body.replaceAll(RegExp(r'[^0-9]'), '');

    var sum = 0;

    for (var i = digits.length - 1; i >= 0; i--) {
      final digit = int.tryParse(digits[i]) ?? 0;
      final positionFromRight = digits.length - i;

      sum += positionFromRight.isOdd ? digit * 3 : digit;
    }

    final check = (10 - (sum % 10)) % 10;
    return check.toString();
  }

  static double _applyDecimals(int value, int decimals) {
    var divisor = 1;

    for (var i = 0; i < decimals; i++) {
      divisor *= 10;
    }

    return value / divisor;
  }

  static String _scaledValue({
    required double value,
    required int decimals,
    required int digits,
  }) {
    var multiplier = 1;

    for (var i = 0; i < decimals; i++) {
      multiplier *= 10;
    }

    final scaled = (value * multiplier).round().abs().toString();
    return _fixedDigits(scaled, digits);
  }

  static String _fixedDigits(String value, int digits) {
    final clean = value.replaceAll(RegExp(r'[^0-9]'), '');

    if (clean.length > digits) {
      return clean.substring(clean.length - digits);
    }

    return clean.padLeft(digits, '0');
  }

  static String _formatMoney(double value) {
    final fixed = value.toStringAsFixed(2).replaceAll('.', ',');
    return 'R\$ $fixed';
  }

  static String _formatNumber(double value) {
    if (value % 1 == 0) return value.toStringAsFixed(0);
    return value.toStringAsFixed(3).replaceAll('.', ',');
  }
}
