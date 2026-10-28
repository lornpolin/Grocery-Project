import 'cart_item.dart';
import 'product.dart';

class Order {
  final String id;
  final List<CartItem> items;
  final double subtotal;
  final double deliveryFee;
  final double serviceFee;
  final String status;
  final String address;
  final String instructions;
  final String paymentMethod;
  final DateTime createdAt;

  const Order({
    required this.id,
    required this.items,
    required this.subtotal,
    required this.deliveryFee,
    required this.serviceFee,
    this.status = 'pending',
    required this.address,
    required this.instructions,
    required this.paymentMethod,
    required this.createdAt,
  });

  double get total => subtotal + deliveryFee + serviceFee;
  int get itemCount => items.fold(0, (sum, i) => sum + i.quantity);

  factory Order.fromJson(
    Map<String, dynamic> json, {
    List<Product> catalog = const [],
    String defaultInstructions = '',
    String defaultPaymentMethod = 'Cash',
  }) {
    final rawItems = (json['items'] as List<dynamic>?) ?? const [];
    final items = rawItems.map((entry) {
      final map = entry as Map<String, dynamic>;
      if (map['product'] is Map<String, dynamic>) {
        return CartItem.fromJson(map);
      }
      final productId = (map['productId'] ?? map['product_id'] ?? '').toString();
      Product? matched;
      for (final p in catalog) {
        if (p.id == productId) {
          matched = p;
          break;
        }
      }
      final product = matched ??
          Product(
            id: productId,
            name: (map['name'] ?? map['product_name'] ?? 'Item').toString(),
            description: '',
            imageUrl: '',
            price: (map['price'] as num?)?.toDouble() ?? 0.0,
            unit: '1 unit',
            categoryId: '',
            stockQuantity: 0,
          );
      return CartItem(
        id: '${json['id']}_$productId',
        product: product,
        quantity: (map['quantity'] as num?)?.toInt() ?? 1,
      );
    }).toList();

    final subtotal = (json['subtotal'] as num?)?.toDouble() ??
        items.fold<double>(0, (s, i) => s + i.subtotal);
    final deliveryFee =
        (json['deliveryFee'] ?? json['delivery_fee'] as num?)?.toDouble() ?? 5.0;
    final apiTotal = (json['total'] as num?)?.toDouble();
    final serviceFee = apiTotal != null
        ? (apiTotal - subtotal - deliveryFee).clamp(0.0, double.infinity)
        : 0.0;

    return Order(
      id: (json['id'] ?? '').toString(),
      items: items,
      subtotal: subtotal,
      deliveryFee: deliveryFee,
      serviceFee: serviceFee,
      status: (json['status'] ?? 'pending').toString(),
      address: (json['address'] ?? 'Phnom Penh').toString(),
      instructions: defaultInstructions,
      paymentMethod: defaultPaymentMethod,
      createdAt: DateTime.tryParse((json['createdAt'] ?? '').toString()) ??
          DateTime.now(),
    );
  }
}
