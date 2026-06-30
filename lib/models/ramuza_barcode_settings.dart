enum RamuzaBarcodeValueMode {
  weight,
  totalPrice,
}

extension RamuzaBarcodeValueModeLabel on RamuzaBarcodeValueMode {
  String get label {
    switch (this) {
      case RamuzaBarcodeValueMode.weight:
        return 'Peso';
      case RamuzaBarcodeValueMode.totalPrice:
        return 'Valor total';
    }
  }
}

RamuzaBarcodeValueMode ramuzaBarcodeValueModeFromName(String? value) {
  return RamuzaBarcodeValueMode.values.firstWhere(
    (mode) => mode.name == value,
    orElse: () => RamuzaBarcodeValueMode.weight,
  );
}

class RamuzaBarcodeSettings {
  const RamuzaBarcodeSettings({
    required this.enabled,
    required this.prefix,
    required this.productCodeDigits,
    required this.valueDigits,
    required this.valueMode,
    required this.weightDecimals,
    required this.priceDecimals,
    required this.hasChecksum,
  });

  final bool enabled;
  final String prefix;
  final int productCodeDigits;
  final int valueDigits;
  final RamuzaBarcodeValueMode valueMode;
  final int weightDecimals;
  final int priceDecimals;
  final bool hasChecksum;

  int get expectedLength {
    return prefix.length + productCodeDigits + valueDigits + (hasChecksum ? 1 : 0);
  }

  RamuzaBarcodeSettings copyWith({
    bool? enabled,
    String? prefix,
    int? productCodeDigits,
    int? valueDigits,
    RamuzaBarcodeValueMode? valueMode,
    int? weightDecimals,
    int? priceDecimals,
    bool? hasChecksum,
  }) {
    return RamuzaBarcodeSettings(
      enabled: enabled ?? this.enabled,
      prefix: prefix ?? this.prefix,
      productCodeDigits: productCodeDigits ?? this.productCodeDigits,
      valueDigits: valueDigits ?? this.valueDigits,
      valueMode: valueMode ?? this.valueMode,
      weightDecimals: weightDecimals ?? this.weightDecimals,
      priceDecimals: priceDecimals ?? this.priceDecimals,
      hasChecksum: hasChecksum ?? this.hasChecksum,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'enabled': enabled,
      'prefix': prefix,
      'productCodeDigits': productCodeDigits,
      'valueDigits': valueDigits,
      'valueMode': valueMode.name,
      'weightDecimals': weightDecimals,
      'priceDecimals': priceDecimals,
      'hasChecksum': hasChecksum,
    };
  }

  factory RamuzaBarcodeSettings.fromMap(Map<String, dynamic> map) {
    return RamuzaBarcodeSettings(
      enabled: _toBool(map['enabled'], fallback: true),
      prefix: map['prefix']?.toString() ?? '20',
      productCodeDigits: _toInt(map['productCodeDigits'], fallback: 4),
      valueDigits: _toInt(map['valueDigits'], fallback: 6),
      valueMode: ramuzaBarcodeValueModeFromName(map['valueMode']?.toString()),
      weightDecimals: _toInt(map['weightDecimals'], fallback: 3),
      priceDecimals: _toInt(map['priceDecimals'], fallback: 2),
      hasChecksum: _toBool(map['hasChecksum'], fallback: true),
    );
  }

  static RamuzaBarcodeSettings defaults() {
    return const RamuzaBarcodeSettings(
      enabled: true,
      prefix: '20',
      productCodeDigits: 4,
      valueDigits: 6,
      valueMode: RamuzaBarcodeValueMode.weight,
      weightDecimals: 3,
      priceDecimals: 2,
      hasChecksum: true,
    );
  }

  static bool _toBool(dynamic value, {required bool fallback}) {
    if (value is bool) return value;

    final text = value?.toString().toLowerCase();

    if (text == 'true') return true;
    if (text == 'false') return false;

    return fallback;
  }

  static int _toInt(dynamic value, {required int fallback}) {
    if (value is int) return value;
    if (value is num) return value.toInt();

    return int.tryParse(value?.toString() ?? '') ?? fallback;
  }
}
