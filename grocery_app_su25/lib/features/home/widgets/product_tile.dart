import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/widgets/product_add_stepper_pill.dart';
import '../../../core/widgets/product_stock_badge.dart';
import '../../../core/widgets/skeleton_loaders.dart';
import '../../../models/product.dart';
import '../../../providers/app_providers.dart';

const _tileTitle = Color(0xFF0F172A);
const _tileMuted = Color(0xFF64748B);

/// Product card with an overhanging "Add" pill, used on Home and in the cart's
/// product suggestions.
class ProductTile extends ConsumerWidget {
  final Product product;

  /// Shows a "added to cart" SnackBar after tapping Add.
  final bool showAddedFeedback;

  const ProductTile({
    super.key,
    required this.product,
    this.showAddedFeedback = true,
  });

  static const double cardHeight = 212;
  static const double buttonOverhang = 14;
  static const double width = 164;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isFavorite = ref.watch(favoriteProvider).contains(product.id);

    return GestureDetector(
      onTap: () => context.push('/product-details?id=${product.id}', extra: product),
      child: SizedBox(
        width: width,
        height: cardHeight + buttonOverhang,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              height: cardHeight,
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.07),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      height: 140,
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          ClipRRect(
                            borderRadius: const BorderRadius.vertical(
                                top: Radius.circular(16)),
                            child: CachedNetworkImage(
                              imageUrl: product.imageUrl,
                              fit: BoxFit.cover,
                              placeholder: (_, _) => const ShimmerBox(
                                borderRadius: BorderRadius.vertical(
                                  top: Radius.circular(16),
                                ),
                              ),
                              errorWidget: (_, _, _) => const Icon(Icons.error),
                            ),
                          ),
                          ProductStockOverlay(product: product),
                          Positioned(
                            top: 8,
                            right: 8,
                            child: InkWell(
                              onTap: () => ref
                                  .read(favoriteProvider.notifier)
                                  .toggleFavorite(product.id),
                              child: Container(
                                padding: const EdgeInsets.all(6),
                                decoration: const BoxDecoration(
                                    color: Colors.white,
                                    shape: BoxShape.circle),
                                child: Icon(
                                  isFavorite
                                      ? Icons.favorite
                                      : Icons.favorite_border,
                                  color: isFavorite ? Colors.red : _tileMuted,
                                  size: 16,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.baseline,
                            textBaseline: TextBaseline.alphabetic,
                            children: [
                              Text('\$${product.price.toStringAsFixed(2)}',
                                  style: const TextStyle(
                                      color: AppColors.primary,
                                      fontWeight: FontWeight.w800,
                                      fontSize: 15)),
                              if (product.originalPrice != null) ...[
                                const SizedBox(width: 6),
                                Text(
                                    '\$${product.originalPrice!.toStringAsFixed(2)}',
                                    style: const TextStyle(
                                        color: Color(0xFF94A3B8),
                                        fontSize: 11,
                                        decoration:
                                            TextDecoration.lineThrough)),
                              ],
                              const Spacer(),
                              Text(product.unit,
                                  style: const TextStyle(
                                      color: _tileMuted, fontSize: 12)),
                            ],
                          ),
                          const SizedBox(height: 2),
                          Text(product.name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                  color: _tileTitle)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: Center(
                child: ProductAddStepperPill(
                  product: product,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
