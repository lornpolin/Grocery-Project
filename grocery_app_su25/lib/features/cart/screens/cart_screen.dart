import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/widgets/product_stock_badge.dart';
import '../../../models/cart_item.dart';
import '../../../models/product.dart';
import '../../../providers/app_providers.dart';
import '../../home/widgets/product_tile.dart';
import '../widgets/checkout_widgets.dart';

/// Step 2 of the order flow: review basket items and suggestions.
class CartScreen extends ConsumerWidget {
  const CartScreen({super.key});

  void _back(BuildContext context) =>
      context.canPop() ? context.pop() : context.go('/home');

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cartItems = ref.watch(cartProvider);
    final subtotal = ref.watch(cartTotalProvider);
    final inCart = {for (final i in cartItems) i.product.id};
    final suggestions =
        ref.watch(productsProvider).where((p) => !inCart.contains(p.id)).toList();
    final total = subtotal + kDeliveryFee;

    return Scaffold(
      backgroundColor: CheckoutColors.pageBg,
      appBar: CheckoutAppBar(title: 'My Order', onBack: () => _back(context)),
      body: cartItems.isEmpty
          ? _EmptyCart(onShop: () => context.go('/home'))
          : ListView(
              padding: EdgeInsets.zero,
              children: [
                const CheckoutStepper(current: 2),
                Container(
                  color: Colors.white,
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
                  child: Column(
                    children: [
                      for (final item in cartItems) _CartLine(item: item),
                      _AddMoreButton(onTap: () => _back(context)),
                    ],
                  ),
                ),
                if (suggestions.isNotEmpty) ...[
                  const Padding(
                    padding: EdgeInsets.fromLTRB(16, 22, 16, 10),
                    child: Text('Products',
                        style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                            color: CheckoutColors.title)),
                  ),
                  SizedBox(
                    height: ProductTile.cardHeight + ProductTile.buttonOverhang + 16,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      clipBehavior: Clip.none,
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                      itemCount: suggestions.length,
                      separatorBuilder: (_, _) => const SizedBox(width: 12),
                      itemBuilder: (_, i) => ProductTile(
                          product: suggestions[i], showAddedFeedback: false),
                    ),
                  ),
                ],
                const SizedBox(height: 16),
                Container(
                  color: Colors.white,
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 18),
                  child: Column(
                    children: [
                      SummaryRow(
                          label: 'Subtotal', amount: subtotal, emphasized: true),
                      const SummaryRow(
                          label: 'Delivery Charge', amount: kDeliveryFee),
                      const Divider(height: 22, color: CheckoutColors.line),
                      TotalWithVoucher(total: total),
                    ],
                  ),
                ),
              ],
            ),
      bottomNavigationBar: cartItems.isEmpty
          ? null
          : Container(
              color: CheckoutColors.pageBg,
              child: SafeArea(
                top: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
                  child: PillButton(
                    label: 'Review Payment & Address',
                    onPressed: () => context.push('/checkout'),
                  ),
                ),
              ),
            ),
    );
  }
}

class _CartLine extends ConsumerWidget {
  final CartItem item;
  const _CartLine({required this.item});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifier = ref.read(cartProvider.notifier);
    final p = item.product;
    final catalog = ref.watch(productsProvider);
    Product liveProduct = p;
    for (final cp in catalog) {
      if (cp.id == p.id) {
        liveProduct = cp;
        break;
      }
    }
    final isOutOfStock = liveProduct.isOutOfStock;
    final reachedMaxStock =
        isOutOfStock || item.quantity >= liveProduct.stockQuantity;
    final exceedsStock =
        !isOutOfStock && item.quantity > liveProduct.stockQuantity;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Stack(
            children: [
              Container(
                width: 58,
                height: 58,
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(10),
                ),
                clipBehavior: Clip.antiAlias,
                child: CachedNetworkImage(
                  imageUrl: p.imageUrl,
                  fit: BoxFit.cover,
                  errorWidget: (_, _, _) => const Icon(
                    Icons.image_not_supported_outlined,
                    color: CheckoutColors.hint,
                  ),
                ),
              ),
              if (isOutOfStock)
                Positioned.fill(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.45),
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(p.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w500,
                          color: CheckoutColors.title)),
                  if (isOutOfStock) ...[
                    const SizedBox(height: 4),
                    ProductStockStatusBadge(product: liveProduct),
                  ] else if (exceedsStock) ...[
                    const SizedBox(height: 4),
                    Text(
                      'Only ${liveProduct.stockQuantity} left in stock',
                      style: const TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFFDC2626),
                      ),
                    ),
                  ],
                  const SizedBox(height: 6),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      Text(money(item.subtotal),
                          style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: AppColors.primary)),
                      if (p.originalPrice != null) ...[
                        const SizedBox(width: 6),
                        Text(money(p.originalPrice! * item.quantity),
                            style: const TextStyle(
                                fontSize: 11,
                                color: CheckoutColors.hint,
                                decoration: TextDecoration.lineThrough)),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ),
          _QtyButton(
            icon: Icons.remove,
            onTap: () => notifier.updateQuantity(p.id, item.quantity - 1),
          ),
          SizedBox(
            width: 30,
            child: Text('${item.quantity}',
                textAlign: TextAlign.center,
                style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: CheckoutColors.title)),
          ),
          _QtyButton(
            icon: Icons.add,
            dimmed: reachedMaxStock,
            onTap: () async {
              final err = await notifier.updateQuantity(
                p.id,
                item.quantity + 1,
              );
              if (err != null && context.mounted) {
                showStockAlertMessage(context, err);
              }
            },
          ),
        ],
      ),
    );
  }
}

class _QtyButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final bool dimmed;
  const _QtyButton({
    required this.icon,
    required this.onTap,
    this.dimmed = false,
  });

  @override
  Widget build(BuildContext context) {
    final color = dimmed ? const Color(0xFFCBD5E1) : AppColors.primary;
    return InkResponse(
      onTap: onTap,
      radius: 18,
      child: Container(
        width: 24,
        height: 24,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: color, width: 1.6),
        ),
        child: Icon(icon, size: 15, color: color),
      ),
    );
  }
}

class _AddMoreButton extends StatelessWidget {
  final VoidCallback onTap;
  const _AddMoreButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: const Padding(
        padding: EdgeInsets.symmetric(vertical: 14),
        child: Row(
          children: [
            Icon(Icons.add, size: 20, color: CheckoutColors.title),
            SizedBox(width: 8),
            Text('Add more item',
                style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                    color: CheckoutColors.title)),
          ],
        ),
      ),
    );
  }
}

class _EmptyCart extends StatelessWidget {
  final VoidCallback onShop;
  const _EmptyCart({required this.onShop});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const CheckoutStepper(current: 2),
        Expanded(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(32, 0, 32, 64),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 112,
                    height: 112,
                    decoration: const BoxDecoration(
                        color: AppColors.primaryLight, shape: BoxShape.circle),
                    child: const Icon(Icons.shopping_basket_outlined,
                        size: 52, color: AppColors.primary),
                  ),
                  const SizedBox(height: 24),
                  const Text('Your basket is empty',
                      style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          color: CheckoutColors.title)),
                  const SizedBox(height: 8),
                  const Text('Add some fresh groceries to get started.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                          fontSize: 14, height: 1.5, color: CheckoutColors.muted)),
                  const SizedBox(height: 28),
                  SizedBox(
                    width: 200,
                    child: PillButton(label: 'Start shopping', onPressed: onShop),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
