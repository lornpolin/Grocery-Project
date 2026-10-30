import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/widgets/product_add_stepper_pill.dart';
import '../../../core/widgets/product_stock_badge.dart';
import '../../../core/widgets/skeleton_loaders.dart';
import '../../../models/category.dart';
import '../../../models/product.dart';
import '../../../providers/app_providers.dart';

const _allProdBg = Color(0xFFF8F9FA);
const _allProdTitle = Color(0xFF0F172A);
const _allProdMuted = Color(0xFF64748B);
const _allProdSoftBlue = Color(0xFFEAF3FC);
const _allProdBorder = Color(0xFFE2E8F0);

class AllProductsScreen extends ConsumerStatefulWidget {
  final String? initialCategoryId;

  const AllProductsScreen({super.key, this.initialCategoryId});

  @override
  ConsumerState<AllProductsScreen> createState() => _AllProductsScreenState();
}

class _AllProductsScreenState extends ConsumerState<AllProductsScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _selectedCategoryId = 'all';
  String _query = '';

  @override
  void initState() {
    super.initState();
    if (widget.initialCategoryId != null &&
        widget.initialCategoryId!.isNotEmpty) {
      _selectedCategoryId = widget.initialCategoryId!;
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _back(BuildContext context) {
    if (context.canPop()) {
      context.pop();
    } else {
      context.go('/home');
    }
  }

  List<Product> _filterProducts(List<Product> allProducts) {
    return allProducts.where((p) {
      final matchesCategory =
          _selectedCategoryId == 'all' || p.categoryId == _selectedCategoryId;
      final q = _query.trim().toLowerCase();
      final matchesQuery = q.isEmpty ||
          p.name.toLowerCase().contains(q) ||
          p.description.toLowerCase().contains(q);
      return matchesCategory && matchesQuery;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final allProducts = ref.watch(productsProvider);
    final categories = ref.watch(categoriesProvider);
    final filteredProducts = _filterProducts(allProducts);

    return Scaffold(
      backgroundColor: _allProdBg,
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
          'All Products',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: _allProdTitle,
          ),
        ),
        actions: [
          if (allProducts.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(right: 16),
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: _allProdSoftBlue,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '${filteredProducts.length} item${filteredProducts.length == 1 ? '' : 's'}',
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
      body: Column(
        children: [
          Container(
            color: Colors.white,
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
            child: Column(
              children: [
                Container(
                  height: 50,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(25),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: Row(
                    children: [
                      SvgPicture.asset(
                        'assets/icons/search.svg',
                        width: 22,
                        height: 22,
                        colorFilter: const ColorFilter.mode(
                          Color(0xFF94A3B8),
                          BlendMode.srcIn,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: TextField(
                          controller: _searchController,
                          onChanged: (v) => setState(() => _query = v),
                          style: const TextStyle(
                            fontSize: 15,
                            color: _allProdTitle,
                          ),
                          decoration: const InputDecoration(
                            hintText: 'Search products',
                            hintStyle: TextStyle(
                              fontSize: 15,
                              color: Color(0xFF94A3B8),
                            ),
                            filled: false,
                            isDense: true,
                            contentPadding: EdgeInsets.zero,
                            border: InputBorder.none,
                            enabledBorder: InputBorder.none,
                            focusedBorder: InputBorder.none,
                            disabledBorder: InputBorder.none,
                          ),
                        ),
                      ),
                      if (_query.isNotEmpty)
                        GestureDetector(
                          onTap: () {
                            _searchController.clear();
                            setState(() => _query = '');
                          },
                          child: const Icon(
                            Icons.close_rounded,
                            size: 18,
                            color: _allProdMuted,
                          ),
                        ),
                    ],
                  ),
                ),
                if (categories.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  _CategoryFilterRow(
                    categories: categories,
                    selectedId: _selectedCategoryId,
                    onSelect: (id) => setState(() => _selectedCategoryId = id),
                  ),
                ],
              ],
            ),
          ),
          const Divider(height: 1, thickness: 1, color: _allProdBorder),
          Expanded(
            child: RefreshIndicator(
              color: AppColors.primary,
              onRefresh: () async {
                await Future.wait([
                  ref.read(categoriesProvider.notifier).refresh(),
                  ref.read(productsProvider.notifier).refresh(),
                ]);
              },
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 36),
                children: [
                  if (allProducts.isEmpty)
                    const CategoryProductGridSkeleton(itemCount: 6)
                  else if (filteredProducts.isEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 64),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 72,
                            height: 72,
                            decoration: const BoxDecoration(
                              color: _allProdSoftBlue,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.search_off_rounded,
                              size: 36,
                              color: AppColors.primary,
                            ),
                          ),
                          const SizedBox(height: 14),
                          const Text(
                            'No products found',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: _allProdTitle,
                            ),
                          ),
                          const SizedBox(height: 6),
                          const Text(
                            'Try clearing your search or selecting another category.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 13,
                              color: _allProdMuted,
                            ),
                          ),
                        ],
                      ),
                    )
                  else
                    GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        mainAxisExtent: 226,
                        crossAxisSpacing: 12,
                        mainAxisSpacing: 18,
                      ),
                      itemCount: filteredProducts.length,
                      itemBuilder: (context, index) {
                        return _AllProductGridCard(
                          product: filteredProducts[index],
                        );
                      },
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CategoryFilterRow extends StatelessWidget {
  final List<Category> categories;
  final String selectedId;
  final ValueChanged<String> onSelect;

  const _CategoryFilterRow({
    required this.categories,
    required this.selectedId,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    final items = <({String id, String name})>[
      (id: 'all', name: 'All'),
      for (final c in categories) (id: c.id, name: c.name),
    ];

    return SizedBox(
      height: 34,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: items.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final item = items[index];
          final isSelected = item.id == selectedId;
          return GestureDetector(
            onTap: () => onSelect(item.id),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: BoxDecoration(
                color: isSelected ? AppColors.primary : _allProdBg,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: isSelected ? AppColors.primary : _allProdBorder,
                ),
              ),
              alignment: Alignment.center,
              child: Text(
                item.name,
                style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                  color: isSelected ? Colors.white : _allProdMuted,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _AllProductGridCard extends ConsumerWidget {
  final Product product;

  const _AllProductGridCard({required this.product});

  static const double _cardHeight = 212;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isFavorite = ref.watch(favoriteProvider).contains(product.id);

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
                            placeholder: (_, _) => const ShimmerBox(
                              borderRadius: BorderRadius.vertical(
                                top: Radius.circular(16),
                              ),
                            ),
                            errorWidget: (_, _, _) =>
                                const Icon(Icons.error_outline),
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
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                isFavorite
                                    ? Icons.favorite_rounded
                                    : Icons.favorite_border_rounded,
                                color: isFavorite ? Colors.red : _allProdMuted,
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
                                color: _allProdMuted,
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
                            color: _allProdTitle,
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

