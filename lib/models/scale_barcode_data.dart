enum ScaleBarcodeMode {
  priceEmbedded,
  weightEmbedded,
  unknown,
}

class ScaleBarcodeData {
  final String rawCode;
  final String productCode;
  final String valueCode;
  final String checkDigit;
  final bool isCheckDigitValid;
  final ScaleBarcodeMode mode;

  const ScaleBarcodeData({
    required this.rawCode,
    required this.productCode,
    required this.valueCode,
    required this.checkDigit,
    required this.isCheckDigitValid,
    required this.mode,
  });

  bool get isValid => rawCode.length == 13 && productCode.isNotEmpty;

  int get valueAsInt => int.tryParse(valueCode) ?? 0;

  double get priceFromBarcode {
    return valueAsInt / 100;
  }

  double get weightKgFromBarcode {
    return valueAsInt / 1000;
  }

  String get modeLabel {
    switch (mode) {
      case ScaleBarcodeMode.priceEmbedded:
        return 'Preço no código';
      case ScaleBarcodeMode.weightEmbedded:
        return 'Peso no código';
      case ScaleBarcodeMode.unknown:
        return 'Desconhecido';
    }
  }

  @override
  String toString() {
    return 'ScaleBarcodeData(rawCode: $rawCode, productCode: $productCode, valueCode: $valueCode, checkDigit: $checkDigit, isCheckDigitValid: $isCheckDigitValid, mode: $mode)';
  }
}
