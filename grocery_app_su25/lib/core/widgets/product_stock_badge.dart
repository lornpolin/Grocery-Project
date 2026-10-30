import 'package:flutter/material.dart';
import '../../models/product.dart';

/// Displays an "Out of Stock" scrim + top-left status badge (or a low-stock
/// badge when stock <= 5) inside a product card's image Stack.
class ProductStockOverlay extends StatelessWidget {
  final Product product;
  final BorderRadiusGeometry borderRadius;

  const ProductStockOverlay({
    super.key,
    required this.product,
    this.borderRadius = const BorderRadius.vertical(top: Radius.circular(16)),
  });

  @override
  Widget build(BuildContext context) {
    if (!product.isOutOfStock && !product.isLowStock) {
      return const SizedBox.shrink();
    }

    return Stack(
      fit: StackFit.expand,
      children: [
        if (product.isOutOfStock)
          IgnorePointer(
            child: ClipRRect(
              borderRadius: borderRadius,
              child: ColoredBox(
                color: Colors.white.withValues(alpha: 0.42),
              ),
            ),
          ),
        Positioned(
          top: 8,
          left: 8,
          child: IgnorePointer(
            child: ProductStockStatusBadge(product: product),
          ),
        ),
      ],
    );
  }
}

/// Standalone pill badge showing a product's stock status.
class ProductStockStatusBadge extends StatelessWidget {
  final Product product;
  final bool showInStock;

  const ProductStockStatusBadge({
    super.key,
    required this.product,
    this.showInStock = false,
  });

  @override
  Widget build(BuildContext context) {
    if (product.isOutOfStock) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: const Color(0xFFFEF2F2),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFFECACA)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 4,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 6,
              height: 6,
              decoration: const BoxDecoration(
                color: Color(0xFFDC2626),
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 5),
            const Text(
              'Out of Stock',
              style: TextStyle(
                fontSize: 10.5,
                fontWeight: FontWeight.w700,
                color: Color(0xFFDC2626),
              ),
            ),
          ],
        ),
      );
    }

    if (product.isLowStock) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: const Color(0xFFFFFBEB),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFFDE68A)),
        ),
        child: Text(
          'Only ${product.stockQuantity} left',
          style: const TextStyle(
            fontSize: 10.5,
            fontWeight: FontWeight.w700,
            color: Color(0xFFD97706),
          ),
        ),
      );
    }

    if (showInStock) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: const Color(0xFFECFDF5),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          'In Stock (${product.stockQuantity})',
          style: const TextStyle(
            fontSize: 11.5,
            fontWeight: FontWeight.w700,
            color: Color(0xFF059669),
          ),
        ),
      );
    }

    return const SizedBox.shrink();
  }
}

/// Shows a floating stock alert message to the user.
void showStockAlertMessage(BuildContext context, String message) {
  if (!context.mounted) return;
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        backgroundColor: const Color(0xFF1E293B),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        duration: const Duration(seconds: 2),
        content: Row(
          children: [
            const Icon(
              Icons.error_outline_rounded,
              color: Color(0xFFF87171),
              size: 20,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 13.5,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
}

