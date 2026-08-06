enum PaymentMethod { dinheiro, pix, debito, credito, fiado, misto }

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
      case PaymentMethod.misto:
        return 'Misto';
    }
  }
}

PaymentMethod paymentMethodFromName(String? value) {
  return PaymentMethod.values.firstWhere(
    (method) => method.name == value,
    orElse: () => PaymentMethod.dinheiro,
  );
}

List<PaymentMethod> get immediatePaymentMethods {
  return const [
    PaymentMethod.dinheiro,
    PaymentMethod.pix,
    PaymentMethod.debito,
    PaymentMethod.credito,
  ];
}
