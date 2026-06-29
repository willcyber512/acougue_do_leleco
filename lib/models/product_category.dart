enum ProductCategory {
  bovina,
  frango,
  suina,
  temperos,
  pimentas,
  charque,
  carvao,
  outros,
}

extension ProductCategoryLabel on ProductCategory {
  String get label {
    switch (this) {
      case ProductCategory.bovina:
        return 'Carne bovina';
      case ProductCategory.frango:
        return 'Frango';
      case ProductCategory.suina:
        return 'Suíno';
      case ProductCategory.temperos:
        return 'Temperos';
      case ProductCategory.pimentas:
        return 'Pimentas';
      case ProductCategory.charque:
        return 'Charque';
      case ProductCategory.carvao:
        return 'Carvão';
      case ProductCategory.outros:
        return 'Outros';
    }
  }
}
