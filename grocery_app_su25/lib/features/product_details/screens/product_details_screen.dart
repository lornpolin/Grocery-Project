import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/widgets/product_stock_badge.dart';
import '../../../models/product.dart';
import '../../../providers/app_providers.dart';
import '../../home/widgets/product_tile.dart';

const _detailBg = Color(0xFFF8F9FA);
const _detailTitle = Color(0xFF0F172A);
const _detailBody = Color(0xFF475569);
const _detailMuted = Color(0xFF64748B);
const _detailSoftBlue = Color(0xFFEAF3FC);

class ProductDetailsScreen extends ConsumerStatefulWidget {
  final Product product;

  const ProductDetailsScreen({super.key, required this.product});

  @override
  ConsumerState<ProductDetailsScreen> createState() =>
      _ProductDetailsScreenState();
}

class _ProductDetailsScreenState extends ConsumerState<ProductDetailsScreen> {
  final PageController _pageController = PageController();
  int _quantity = 1;
  int _imagePage = 0;

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      ref.read(productsProvider.notifier).refreshProduct(widget.product.id);
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _back(BuildContext context) {
    if (context.canPop()) {
      context.pop();
    } else {
      context.go('/home');
    }
  }

  @override
  Widget build(BuildContext context) {
    final catalog = ref.watch(productsProvider);
    Product product = widget.product;
    for (final p in catalog) {
      if (p.id == widget.product.id) {
        product = p;
        break;
      }
    }

    final cartItems = ref.watch(cartProvider);
    int inCartQty = 0;
    for (final item in cartItems) {
      if (item.product.id == product.id) {
        inCartQty = item.quantity;
        break;
      }
    }

    final isOutOfStock = product.isOutOfStock;
    final remainingStock = (product.stockQuantity - inCartQty).clamp(
      0,
      product.stockQuantity,
    );
    final effectiveQty = (!isOutOfStock && remainingStock > 0)
        ? _quantity.clamp(1, remainingStock)
        : 1;

    final isFavorite = ref.watch(favoriteProvider).contains(product.id);
    final relatedProducts = catalog.where((p) => p.id != product.id).toList();
    final totalPrice = product.price * effectiveQty;

    return Scaffold(
      backgroundColor: _detailBg,
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
          'Product Details',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: _detailTitle,
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: IconButton(
              onPressed: () {
                ref.read(favoriteProvider.notifier).toggleFavorite(product.id);
              },
              icon: Icon(
                isFavorite
                    ? Icons.favorite_rounded
                    : Icons.favorite_border_rounded,
                color: isFavorite ? Colors.red : AppColors.primary,
                size: 25,
              ),
            ),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.only(bottom: 24),
        children: [
          _HeroWithSummaryCard(
            product: product,
            pageController: _pageController,
            currentPage: _imagePage,
            onPageChanged: (i) => setState(() => _imagePage = i),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Description',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: _detailTitle,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '${product.description} ',
                  style: const TextStyle(
                    fontSize: 14,
                    height: 1.55,
                    color: _detailBody,
                  ),
                ),
                const SizedBox(height: 22),
                const Text(
                  'Nutrition',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: _detailTitle,
                  ),
                ),
                const SizedBox(height: 12),
                const _NutritionGrid(),
              ],
            ),
          ),
          if (relatedProducts.isNotEmpty) ...[
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 24, 16, 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Related Products',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: _detailTitle,
                    ),
                  ),
                  GestureDetector(
                    onTap: () => context.push('/products'),
                    child: const Text(
                      'See all',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: _detailMuted,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(
              height: ProductTile.cardHeight + ProductTile.buttonOverhang + 12,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                clipBehavior: Clip.none,
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 4,
                ),
                itemCount: relatedProducts.length,
                separatorBuilder: (_, _) => const SizedBox(width: 12),
                itemBuilder: (_, i) => ProductTile(product: relatedProducts[i]),
              ),
            ),
          ],
        ],
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 16,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
            child: Row(
              children: [
                Container(
                  height: 48,
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(26),
                    border: Border.all(
                      color: isOutOfStock
                          ? const Color(0xFFCBD5E1)
                          : AppColors.primary,
                      width: 1.3,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      InkResponse(
                        onTap: () {
                          if (!isOutOfStock && effectiveQty > 1) {
                            setState(() => _quantity = effectiveQty - 1);
                          }
                        },
                        radius: 18,
                        child: Padding(
                          padding: const EdgeInsets.all(6),
                          child: Icon(
                            Icons.remove_rounded,
                            color: isOutOfStock
                                ? const Color(0xFFCBD5E1)
                                : AppColors.primary,
                            size: 20,
                          ),
                        ),
                      ),
                      SizedBox(
                        width: 28,
                        child: Text(
                          isOutOfStock ? '0' : '$effectiveQty',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: isOutOfStock
                                ? const Color(0xFF94A3B8)
                                : _detailTitle,
                          ),
                        ),
                      ),
                      InkResponse(
                        onTap: () {
                          if (isOutOfStock) {
                            HapticFeedback.heavyImpact();
                            showStockAlertMessage(
                              context,
                              '${product.name} is currently out of stock',
                            );
                            return;
                          }
                          if (effectiveQty >= remainingStock) {
                            HapticFeedback.heavyImpact();
                            showStockAlertMessage(
                              context,
                              'Only ${product.stockQuantity} left in stock for ${product.name}',
                            );
                            return;
                          }
                          setState(() => _quantity = effectiveQty + 1);
                        },
                        radius: 18,
                        child: Padding(
                          padding: const EdgeInsets.all(6),
                          child: Icon(
                            Icons.add_rounded,
                            color:
                                (isOutOfStock || effectiveQty >= remainingStock)
                                ? const Color(0xFFCBD5E1)
                                : AppColors.primary,
                            size: 20,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(28),
                      boxShadow: isOutOfStock
                          ? null
                          : [
                              BoxShadow(
                                color: AppColors.primary.withValues(
                                  alpha: 0.35,
                                ),
                                blurRadius: 12,
                                offset: const Offset(0, 4),
                              ),
                            ],
                    ),
                    child: SizedBox(
                      height: 50,
                      child: ElevatedButton(
                        onPressed: () async {
                          if (isOutOfStock) {
                            HapticFeedback.heavyImpact();
                            showStockAlertMessage(
                              context,
                              '${product.name} is currently out of stock',
                            );
                            return;
                          }
                          if (remainingStock <= 0) {
                            HapticFeedback.heavyImpact();
                            showStockAlertMessage(
                              context,
                              'Only ${product.stockQuantity} left in stock for ${product.name}',
                            );
                            return;
                          }
                          final err = await ref
                              .read(cartProvider.notifier)
                              .addToCart(product, quantity: effectiveQty);
                          if (!context.mounted) return;
                          if (err != null) {
                            showStockAlertMessage(context, err);
                            return;
                          }
                          ScaffoldMessenger.of(context)
                            ..hideCurrentSnackBar()
                            ..showSnackBar(
                              SnackBar(
                                content: Text(
                                  '$effectiveQty × ${product.name} added to cart',
                                ),
                                action: SnackBarAction(
                                  label: 'View cart',
                                  textColor: AppColors.primarySoft,
                                  onPressed: () => context.push('/cart'),
                                ),
                              ),
                            );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: isOutOfStock
                              ? const Color(0xFFE2E8F0)
                              : AppColors.primary,
                          foregroundColor: isOutOfStock
                              ? const Color(0xFF64748B)
                              : Colors.white,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(28),
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              isOutOfStock
                                  ? Icons.error_outline_rounded
                                  : Icons.shopping_basket_outlined,
                              color: isOutOfStock
                                  ? const Color(0xFF64748B)
                                  : Colors.white,
                              size: 21,
                            ),
                            const SizedBox(width: 10),
                            Flexible(
                              child: Text(
                                isOutOfStock
                                    ? 'Out of Stock'
                                    : 'Add to Cart | \$${totalPrice.toStringAsFixed(2)}',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 15.5,
                                  fontWeight: FontWeight.w700,
                                  color: isOutOfStock
                                      ? const Color(0xFF64748B)
                                      : Colors.white,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _HeroWithSummaryCard extends StatelessWidget {
  final Product product;
  final PageController pageController;
  final int currentPage;
  final ValueChanged<int> onPageChanged;

  const _HeroWithSummaryCard({
    required this.product,
    required this.pageController,
    required this.currentPage,
    required this.onPageChanged,
  });

  void _goToPage(int index) {
    if (!pageController.hasClients) return;
    pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 260),
      curve: Curves.easeOutCubic,
    );
  }

  @override
  Widget build(BuildContext context) {
    final oldPrice = product.originalPrice ?? (product.price * 1.25);
    final gallery = product.images.isNotEmpty
        ? product.images
        : (product.imageUrl.isNotEmpty ? [product.imageUrl] : const <String>[]);

    return Column(
      children: [
        SizedBox(
          height: 240,
          width: double.infinity,
          child: Stack(
            fit: StackFit.expand,
            children: [
              PageView.builder(
                controller: pageController,
                physics: const BouncingScrollPhysics(),
                itemCount: gallery.length,
                onPageChanged: onPageChanged,
                itemBuilder: (context, index) {
                  return CachedNetworkImage(
                    imageUrl: gallery[index],
                    fit: BoxFit.cover,
                    placeholder: (_, _) => const Center(
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                    errorWidget: (_, _, _) => const Icon(Icons.error_outline),
                  );
                },
              ),
              if (product.isOutOfStock)
                IgnorePointer(
                  child: ColoredBox(
                    color: Colors.white.withValues(alpha: 0.38),
                  ),
                ),
              if (gallery.length > 1 && currentPage > 0)
                Positioned(
                  left: 12,
                  top: 0,
                  bottom: 28,
                  child: Center(
                    child: _GalleryNavButton(
                      icon: Icons.chevron_left_rounded,
                      onTap: () => _goToPage(currentPage - 1),
                    ),
                  ),
                ),
              if (gallery.length > 1 && currentPage < gallery.length - 1)
                Positioned(
                  right: 12,
                  top: 0,
                  bottom: 28,
                  child: Center(
                    child: _GalleryNavButton(
                      icon: Icons.chevron_right_rounded,
                      onTap: () => _goToPage(currentPage + 1),
                    ),
                  ),
                ),
              if (gallery.length > 1)
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 42,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(gallery.length, (index) {
                      final active = index == currentPage;
                      return GestureDetector(
                        onTap: () => _goToPage(index),
                        behavior: HitTestBehavior.opaque,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 4,
                            vertical: 6,
                          ),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 220),
                            curve: Curves.easeOut,
                            width: active ? 20 : 8,
                            height: 8,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(4),
                              color: active
                                  ? AppColors.primary
                                  : Colors.white.withValues(alpha: 0.8),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.12),
                                  blurRadius: 4,
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    }),
                  ),
                ),
            ],
          ),
        ),
        Transform.translate(
          offset: const Offset(0, -28),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 18),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 16,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${product.name}',
                          style: const TextStyle(
                            fontSize: 21,
                            fontWeight: FontWeight.w800,
                            height: 1.25,
                            color: _detailTitle,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Fresh • Per ${product.unit}',
                          style: const TextStyle(
                            fontSize: 13.5,
                            fontWeight: FontWeight.w500,
                            color: _detailBody,
                          ),
                        ),
                        const SizedBox(height: 14),
                        Wrap(
                          spacing: 8,
                          runSpacing: 6,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            ProductStockStatusBadge(
                              product: product,
                              showInStock: true,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '\$${oldPrice.toStringAsFixed(2)}',
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: _detailMuted,
                          decoration: TextDecoration.lineThrough,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '\$${product.price.toStringAsFixed(2)}',
                        style: const TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.w800,
                          color: AppColors.primary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      const Text(
                        'Approx.',
                        style: TextStyle(fontSize: 12, color: _detailMuted),
                      ),
                      Text(
                        product.unit,
                        style: const TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w700,
                          color: _detailBody,
                        ),
                      ),
                    ],
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

class _NutritionGrid extends StatelessWidget {
  const _NutritionGrid();

  static const _items = [
    ('Calories', '250 kcal'),
    ('Protein', '26g'),
    ('Fat', '15g'),
    ('Iron', '15% DV'),
  ];

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisExtent: 74,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: _items.length,
      itemBuilder: (context, index) {
        final item = _items[index];
        return Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.025),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                item.$1,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: _detailMuted,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                item.$2,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: _detailTitle,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _GalleryNavButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _GalleryNavButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white.withValues(alpha: 0.85),
      shape: const CircleBorder(),
      elevation: 2,
      shadowColor: Colors.black.withValues(alpha: 0.15),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: SizedBox(
          width: 34,
          height: 34,
          child: Icon(icon, size: 22, color: _detailTitle),
        ),
      ),
    );
  }
}
