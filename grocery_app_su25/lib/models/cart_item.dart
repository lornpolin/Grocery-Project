import 'product.dart';

class CartItem {
  final String id;
  final Product product;
  final int quantity;

  const CartItem({
    required this.id,
    required this.product,
    required this.quantity,
  });

  double get subtotal => product.price * quantity;

  factory CartItem.fromJson(Map<String, dynamic> json) {
    final productJson =
        (json['product'] as Map<String, dynamic>?) ?? const <String, dynamic>{};
    return CartItem(
      id: (json['id'] ?? '').toString(),
      product: Product.fromJson(productJson),
      quantity: (json['quantity'] as num?)?.toInt() ?? 1,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'product': product.toJson(),
      'quantity': quantity,
    };
  }

  CartItem copyWith({
    String? id,
    Product? product,
    int? quantity,
  }) {
    return CartItem(
      id: id ?? this.id,
      product: product ?? this.product,
      quantity: quantity ?? this.quantity,
    );
  }
}
