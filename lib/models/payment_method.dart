enum PaymentMethod {
  dinheiro,
  pix,
  debito,
  credito,
  fiado,
}

extension PaymentMethodLabel on PaymentMethod {
  String get label {
    switch (this) {
      case PaymentMethod.dinheiro:
        return 'Dinheiro';
      case PaymentMethod.pix:
        return 'Pix';
      case PaymentMethod.debito:
        return 'Débito';
      case PaymentMethod.credito:
        return 'Crédito';
      case PaymentMethod.fiado:
        return 'Fiado';
    }
  }
}

PaymentMethod paymentMethodFromName(String? value) {
  return PaymentMethod.values.firstWhere(
    (method) => method.name == value,
    orElse: () => PaymentMethod.dinheiro,
  );
}
