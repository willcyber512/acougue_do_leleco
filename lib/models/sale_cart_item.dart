import 'product.dart';

class SaleCartItem {
  const SaleCartItem({
    required this.product,
    required this.quantity,
  });

  final Product product;
  final double quantity;

  double get subtotal => product.salePrice * quantity;

  SaleCartItem copyWith({
    Product? product,
    double? quantity,
  }) {
    return SaleCartItem(
      product: product ?? this.product,
      quantity: quantity ?? this.quantity,
    );
  }
}
