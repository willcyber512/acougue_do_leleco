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

  double get expectedCash => openingAmount + moneySales;

  double get difference => countedAmount - expectedCash;

  double get totalSold {
    return moneySales + pixSales + debitSales + creditSales + fiadoSales;
  }

  CashClosure copyWith({
    String? id,
    String? dayKey,
    double? openingAmount,
    double? countedAmount,
    double? moneySales,
    double? pixSales,
    double? debitSales,
    double? creditSales,
    double? fiadoSales,
    double? canceledSales,
    int? salesCount,
    String? notes,
    DateTime? createdAt,
  }) {
    return CashClosure(
      id: id ?? this.id,
      dayKey: dayKey ?? this.dayKey,
      openingAmount: openingAmount ?? this.openingAmount,
      countedAmount: countedAmount ?? this.countedAmount,
      moneySales: moneySales ?? this.moneySales,
      pixSales: pixSales ?? this.pixSales,
      debitSales: debitSales ?? this.debitSales,
      creditSales: creditSales ?? this.creditSales,
      fiadoSales: fiadoSales ?? this.fiadoSales,
      canceledSales: canceledSales ?? this.canceledSales,
      salesCount: salesCount ?? this.salesCount,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
    );
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

String cashClosureDayKey(DateTime value) {
  final day = value.day.toString().padLeft(2, '0');
  final month = value.month.toString().padLeft(2, '0');

  return '${value.year}-$month-$day';
}
