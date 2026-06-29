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
