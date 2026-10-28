import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/widgets/product_add_stepper_pill.dart';
import '../../../models/product.dart';
import '../../../providers/app_providers.dart';
import '../../cart/widgets/checkout_widgets.dart';

const _favBg = Color(0xFFF8F9FA);
const _favTitle = Color(0xFF0F172A);
const _favMuted = Color(0xFF64748B);
const _favSoftBlue = Color(0xFFEAF3FC);

class FavoritesScreen extends ConsumerWidget {
  const FavoritesScreen({super.key});

  void _back(BuildContext context) {
    if (context.canPop()) {
      context.pop();
    } else {
      context.go('/profile');
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final favoriteIds = ref.watch(favoriteProvider);
    final allProducts = ref.watch(productsProvider);
    final favoriteProducts =
        allProducts.where((p) => favoriteIds.contains(p.id)).toList();

    return Scaffold(
      backgroundColor: _favBg,
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        toolbarHeight: 56,
        leadingWidth: 64,
        leading: Center(
          child: InkResponse(
            onTap: () => _back(context),
            radius: 22,
            child: Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.primary, width: 1.6),
              ),
              child: const Icon(
                Icons.arrow_back_rounded,
                size: 18,
                color: AppColors.primary,
              ),
            ),
          ),
        ),
        title: const Text(
          'Favorites',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: _favTitle,
          ),
        ),
        actions: [
          if (favoriteProducts.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(right: 16),
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: _favSoftBlue,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '${favoriteProducts.length} item${favoriteProducts.length == 1 ? '' : 's'}',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: AppColors.primary,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
      body: favoriteProducts.isEmpty
          ? const _EmptyFavorites()
          : ListView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 36),
              children: [
                _FavoritesBannerCard(
                  count: favoriteProducts.length,
                  onAddAll: () {
                    final cartNotifier = ref.read(cartProvider.notifier);
                    for (final product in favoriteProducts) {
                      cartNotifier.addToCart(product);
                    }
                    ScaffoldMessenger.of(context)
                      ..hideCurrentSnackBar()
                      ..showSnackBar(
                        SnackBar(
                          content: Text(
                            'Added ${favoriteProducts.length} item${favoriteProducts.length == 1 ? '' : 's'} to cart',
                          ),
                          action: SnackBarAction(
                            label: 'View cart',
                            textColor: AppColors.primarySoft,
                            onPressed: () => context.push('/cart'),
                          ),
                        ),
                      );
                  },
                ),
                const SizedBox(height: 16),
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    mainAxisExtent: 226,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 18,
                  ),
                  itemCount: favoriteProducts.length,
                  itemBuilder: (context, index) {
                    return _FavoriteProductCard(
                      product: favoriteProducts[index],
                    );
                  },
                ),
              ],
            ),
    );
  }
}

class _FavoritesBannerCard extends StatelessWidget {
  final int count;
  final VoidCallback onAddAll;

  const _FavoritesBannerCard({
    required this.count,
    required this.onAddAll,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: _favSoftBlue,
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(
              Icons.favorite_rounded,
              color: AppColors.primary,
              size: 23,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Saved Items',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: _favTitle,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '$count favorite product${count == 1 ? '' : 's'}',
                  style: const TextStyle(
                    fontSize: 12.5,
                    color: _favMuted,
                  ),
                ),
              ],
            ),
          ),
          TextButton.icon(
            onPressed: onAddAll,
            style: TextButton.styleFrom(
              foregroundColor: AppColors.primary,
              backgroundColor: _favSoftBlue,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
            ),
            icon: const Icon(Icons.add_shopping_cart_rounded, size: 16),
            label: const Text(
              'Add All',
              style: TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FavoriteProductCard extends ConsumerWidget {
  final Product product;

  const _FavoriteProductCard({required this.product});

  static const double _cardHeight = 212;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return GestureDetector(
      onTap: () =>
          context.push('/product-details?id=${product.id}', extra: product),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: _cardHeight,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    height: 138,
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        ClipRRect(
                          borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(16),
                          ),
                          child: CachedNetworkImage(
                            imageUrl: product.imageUrl,
                            fit: BoxFit.cover,
                            placeholder: (_, _) => const Center(
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                            errorWidget: (_, _, _) =>
                                const Icon(Icons.error_outline),
                          ),
                        ),
                        Positioned(
                          top: 8,
                          right: 8,
                          child: InkWell(
                            onTap: () {
                              ref
                                  .read(favoriteProvider.notifier)
                                  .toggleFavorite(product.id);
                              ScaffoldMessenger.of(context)
                                ..hideCurrentSnackBar()
                                ..showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      '${product.name} removed from favorites',
                                    ),
                                    duration: const Duration(seconds: 2),
                                  ),
                                );
                            },
                            child: Container(
                              padding: const EdgeInsets.all(6),
                              decoration: const BoxDecoration(
                                color: Colors.white,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.favorite_rounded,
                                color: Colors.red,
                                size: 17,
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
                            Text(
                              '\$${product.price.toStringAsFixed(2)}',
                              style: const TextStyle(
                                color: AppColors.primary,
                                fontWeight: FontWeight.w800,
                                fontSize: 15,
                              ),
                            ),
                            if (product.originalPrice != null) ...[
                              const SizedBox(width: 5),
                              Flexible(
                                child: Text(
                                  '\$${product.originalPrice!.toStringAsFixed(2)}',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    color: Color(0xFF94A3B8),
                                    fontSize: 11,
                                    decoration: TextDecoration.lineThrough,
                                  ),
                                ),
                              ),
                            ],
                            const Spacer(),
                            Text(
                              product.unit,
                              style: const TextStyle(
                                color: _favMuted,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 3),
                        Text(
                          product.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 14.5,
                            fontWeight: FontWeight.w700,
                            color: _favTitle,
                          ),
                        ),
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
    );
  }
}

class _EmptyFavorites extends StatelessWidget {
  const _EmptyFavorites();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(32, 0, 32, 64),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 112,
              height: 112,
              decoration: const BoxDecoration(
                color: AppColors.primaryLight,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.favorite_border_rounded,
                size: 52,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'No favorites yet',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: _favTitle,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Tap the heart icon on any product to save your favorite items here.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                height: 1.5,
                color: _favMuted,
              ),
            ),
            const SizedBox(height: 28),
            SizedBox(
              width: 200,
              child: PillButton(
                label: 'Start shopping',
                onPressed: () => context.go('/home'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

