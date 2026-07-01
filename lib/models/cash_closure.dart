class CashClosure {
  const CashClosure({
    required this.id,
    required this.dayKey,
    required this.openingAmount,
    required this.countedAmount,
    required this.moneySales,
    required this.pixSales,
    required this.debitSales,
    required this.creditSales,
    required this.fiadoSales,
    required this.canceledSales,
    required this.salesCount,
    required this.notes,
    required this.createdAt,
    this.cashInAmount = 0,
    this.cashOutAmount = 0,
  });

  final String id;
  final String dayKey;
  final double openingAmount;
  final double countedAmount;
  final double moneySales;
  final double pixSales;
  final double debitSales;
  final double creditSales;
  final double fiadoSales;
  final double canceledSales;
  final int salesCount;
  final String notes;
  final DateTime createdAt;

  /// Reforço/entrada manual de dinheiro no caixa.
  final double cashInAmount;

  /// Sangria/retirada manual de dinheiro do caixa.
  final double cashOutAmount;

  double get totalSales {
    return moneySales + pixSales + debitSales + creditSales + fiadoSales;
  }

  double get expectedCash {
    return openingAmount + moneySales + cashInAmount - cashOutAmount;
  }

  double get difference {
    return countedAmount - expectedCash;
  }

  bool get isBalanced {
    return difference.abs() < 0.01;
  }

  String get statusLabel {
    if (isBalanced) return 'Caixa batendo';
    if (difference > 0) return 'Sobra no caixa';
    return 'Falta no caixa';
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'dayKey': dayKey,
      'openingAmount': openingAmount,
      'countedAmount': countedAmount,
      'moneySales': moneySales,
      'pixSales': pixSales,
      'debitSales': debitSales,
      'creditSales': creditSales,
      'fiadoSales': fiadoSales,
      'canceledSales': canceledSales,
      'salesCount': salesCount,
      'notes': notes,
      'createdAt': createdAt.toIso8601String(),
      'cashInAmount': cashInAmount,
      'cashOutAmount': cashOutAmount,
    };
  }

  factory CashClosure.fromMap(Map<String, dynamic> map) {
    return CashClosure(
      id: map['id']?.toString() ?? '',
      dayKey: map['dayKey']?.toString() ?? '',
      openingAmount: _toDouble(map['openingAmount']),
      countedAmount: _toDouble(map['countedAmount']),
      moneySales: _toDouble(map['moneySales']),
      pixSales: _toDouble(map['pixSales']),
      debitSales: _toDouble(map['debitSales']),
      creditSales: _toDouble(map['creditSales']),
      fiadoSales: _toDouble(map['fiadoSales']),
      canceledSales: _toDouble(map['canceledSales']),
      salesCount: _toInt(map['salesCount']),
      notes: map['notes']?.toString() ?? '',
      createdAt: _toDate(map['createdAt']),
      cashInAmount: _toDouble(map['cashInAmount']),
      cashOutAmount: _toDouble(map['cashOutAmount']),
    );
  }

  static double _toDouble(dynamic value) {
    if (value is num) return value.toDouble();

    final text = value?.toString().replaceAll(',', '.') ?? '';
    return double.tryParse(text) ?? 0;
  }

  static int _toInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();

    return int.tryParse(value?.toString() ?? '') ?? 0;
  }

  static DateTime _toDate(dynamic value) {
    return DateTime.tryParse(value?.toString() ?? '') ?? DateTime.now();
  }
}

String cashClosureDayKey(DateTime date) {
  final year = date.year.toString().padLeft(4, '0');
  final month = date.month.toString().padLeft(2, '0');
  final day = date.day.toString().padLeft(2, '0');

  return '$year-$month-$day';
}
