enum ProductUnit {
  kg,
  unidade,
  pacote,
}

extension ProductUnitLabel on ProductUnit {
  String get label {
    switch (this) {
      case ProductUnit.kg:
        return 'kg';
      case ProductUnit.unidade:
        return 'un';
      case ProductUnit.pacote:
        return 'pct';
    }
  }
}

ProductUnit productUnitFromName(String? value) {
  return ProductUnit.values.firstWhere(
    (unit) => unit.name == value,
    orElse: () => ProductUnit.kg,
  );
}
