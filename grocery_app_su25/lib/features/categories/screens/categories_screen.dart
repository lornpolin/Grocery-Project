import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/widgets/category_icon.dart';
import '../../../core/widgets/product_add_stepper_pill.dart';
import '../../../core/widgets/skeleton_loaders.dart';
import '../../../models/category.dart';
import '../../../models/product.dart';
import '../../../providers/app_providers.dart';

const _catBg = Color(0xFFF5F6F8);
const _catTitle = Color(0xFF0F172A);
const _catMuted = Color(0xFF64748B);
const _catBorder = Color(0xFFEFF2F6);
const _catSoftBlue = Color(0xFFEAF3FC);

const _allCategory = Category(
  id: 'all',
  name: 'Groceries',
  iconAsset: '',
);

class CategoriesScreen extends ConsumerStatefulWidget {
  final String? initialCategoryId;

  const CategoriesScreen({super.key, this.initialCategoryId});

  @override
  ConsumerState<CategoriesScreen> createState() => _CategoriesScreenState();
}

class _CategoriesScreenState extends ConsumerState<CategoriesScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _selectedId = 'all';
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    if (widget.initialCategoryId != null &&
        widget.initialCategoryId!.isNotEmpty) {
      _selectedId = widget.initialCategoryId!;
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant CategoriesScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialCategoryId != oldWidget.initialCategoryId) {
      _selectedId =
          (widget.initialCategoryId != null &&
                  widget.initialCategoryId!.isNotEmpty)
              ? widget.initialCategoryId!
              : 'all';
    }
  }

  List<Product> _filteredProducts(
    List<Product> allProducts,
    Category selected,
  ) {
    final q = _searchQuery.trim().toLowerCase();
    return allProducts.where((p) {
      final matchesCat = selected.id == 'all' || p.categoryId == selected.id;
      final matchesQuery = q.isEmpty ||
          p.name.toLowerCase().contains(q) ||
          p.description.toLowerCase().contains(q);
      return matchesCat && matchesQuery;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final apiCategories = ref.watch(categoriesProvider);
    final allProducts = ref.watch(productsProvider);
    final sidebarCategories = <Category>[_allCategory, ...apiCategories];

    Category selectedCategory = _allCategory;
    for (final c in sidebarCategories) {
      if (c.id == _selectedId) {
        selectedCategory = c;
        break;
      }
    }

    final products = _filteredProducts(allProducts, selectedCategory);

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            const _TopDeliveryHeader(),
            _TopSearchBar(
              controller: _searchController,
              query: _searchQuery,
              onChanged: (v) => setState(() => _searchQuery = v),
              onClear: () {
                _searchController.clear();
                setState(() => _searchQuery = '');
                FocusScope.of(context).unfocus();
              },
            ),
            const Divider(height: 1, thickness: 1, color: _catBorder),
            Expanded(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Container(
                    width: 86,
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      border: Border(
                        right: BorderSide(color: _catBorder, width: 1),
                      ),
                    ),
                    child: apiCategories.isEmpty
                        ? ListView.separated(
                            padding: const EdgeInsets.fromLTRB(10, 16, 10, 110),
                            itemCount: 7,
                            separatorBuilder: (_, _) =>
                                const SizedBox(height: 18),
                            itemBuilder: (context, index) {
                              if (index == 0) {
                                return _SidebarCategoryTile(
                                  category: _allCategory,
                                  isSelected: true,
                                  onTap: () {},
                                );
                              }
                              return const SidebarCategoryTileSkeleton();
                            },
                          )
                        : ListView.separated(
                            padding: const EdgeInsets.fromLTRB(10, 16, 10, 110),
                            itemCount: sidebarCategories.length,
                            separatorBuilder: (_, _) =>
                                const SizedBox(height: 18),
                            itemBuilder: (context, index) {
                              final category = sidebarCategories[index];
                              final isSelected =
                                  category.id == selectedCategory.id;
                              return _SidebarCategoryTile(
                                category: category,
                                isSelected: isSelected,
                                onTap: () =>
                                    setState(() => _selectedId = category.id),
                              );
                            },
                          ),
                  ),
                  Expanded(
                    child: ColoredBox(
                      color: _catBg,
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
                          padding: const EdgeInsets.fromLTRB(12, 14, 12, 110),
                          children: [
                            _CategoryHeaderBanner(category: selectedCategory),
                            const SizedBox(height: 14),
                            if (allProducts.isEmpty)
                              const CategoryProductGridSkeleton()
                            else if (products.isEmpty)
                              const Padding(
                                padding: EdgeInsets.symmetric(vertical: 48),
                                child: Center(
                                  child: Text(
                                    'No products in this category',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: _catMuted,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                              )
                            else
                              GridView.builder(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                gridDelegate:
                                    const SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: 2,
                                  mainAxisExtent: 218,
                                  crossAxisSpacing: 10,
                                  mainAxisSpacing: 16,
                                ),
                                itemCount: products.length,
                                itemBuilder: (context, index) {
                                  return _CategoryProductCard(
                                    product: products[index],
                                  );
                                },
                              ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TopDeliveryHeader extends ConsumerWidget {
  const _TopDeliveryHeader();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedAddress = ref.watch(selectedAddressProvider);
    final locationLabel = selectedAddress?.headerLocation ?? 'Phnom Penh';

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      child: Row(
        children: [
          Expanded(
            child: InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: () => context.push('/addresses'),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: const BoxDecoration(
                      color: _catSoftBlue,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.location_on,
                      color: AppColors.primary,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'DELIVERY TO',
                          style: TextStyle(
                            fontSize: 10,
                            letterSpacing: 1,
                            fontWeight: FontWeight.w600,
                            color: _catMuted,
                          ),
                        ),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            ConstrainedBox(
                              constraints: const BoxConstraints(maxWidth: 140),
                              child: Text(
                                locationLabel,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w800,
                                  color: _catTitle,
                                ),
                              ),
                            ),
                            const SizedBox(width: 4),
                            const Icon(
                              Icons.keyboard_arrow_down_rounded,
                              size: 18,
                              color: _catTitle,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          IconButton(
            onPressed: () {},
            icon: SvgPicture.asset(
              'assets/icons/notification.svg',
              width: 26,
              height: 26,
              colorFilter: const ColorFilter.mode(_catMuted, BlendMode.srcIn),
            ),
          ),
        ],
      ),
    );
  }
}

class _TopSearchBar extends StatelessWidget {
  final TextEditingController controller;
  final String query;
  final ValueChanged<String> onChanged;
  final VoidCallback onClear;

  const _TopSearchBar({
    required this.controller,
    required this.query,
    required this.onChanged,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: Container(
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
                controller: controller,
                onChanged: onChanged,
                style: const TextStyle(
                  fontSize: 15,
                  color: _catTitle,
                ),
                decoration: const InputDecoration(
                  hintText: 'Search products',
                  hintStyle: TextStyle(
                    color: Color(0xFF94A3B8),
                    fontSize: 15,
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
            if (query.isNotEmpty)
              GestureDetector(
                onTap: onClear,
                child: const Icon(
                  Icons.close_rounded,
                  size: 18,
                  color: _catMuted,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _SidebarCategoryTile extends StatelessWidget {
  final Category category;
  final bool isSelected;
  final VoidCallback onTap;

  const _SidebarCategoryTile({
    required this.category,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 54,
            height: 54,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  ColoredBox(
                    color: isSelected ? _catSoftBlue : const Color(0xFFF5F6F8),
                    child: Center(
                      child: CategoryIcon(category: category, size: 28),
                    ),
                  ),
                  if (isSelected)
                    Positioned(
                      left: 0,
                      top: 8,
                      bottom: 8,
                      child: Container(
                        width: 3.5,
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            category.name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12,
              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
              color: isSelected ? AppColors.primary : _catMuted,
            ),
          ),
        ],
      ),
    );
  }
}

class _CategoryHeaderBanner extends StatelessWidget {
  final Category category;

  const _CategoryHeaderBanner({required this.category});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
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
            width: 46,
            height: 46,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: _catSoftBlue,
              borderRadius: BorderRadius.circular(14),
            ),
            child: CategoryIcon(category: category, size: 26),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              category.name,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: _catTitle,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CategoryProductCard extends ConsumerWidget {
  final Product product;

  const _CategoryProductCard({required this.product});

  static const double _cardHeight = 204;

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
                    height: 132,
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
                        Positioned(
                          top: 8,
                          right: 8,
                          child: InkWell(
                            onTap: () => ref
                                .read(favoriteProvider.notifier)
                                .toggleFavorite(product.id),
                            child: Container(
                              padding: const EdgeInsets.all(5),
                              decoration: const BoxDecoration(
                                color: Colors.white,
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                isFavorite
                                    ? Icons.favorite
                                    : Icons.favorite_border,
                                color: isFavorite ? Colors.red : _catMuted,
                                size: 16,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(10, 8, 10, 0),
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
                                fontSize: 14,
                              ),
                            ),
                            if (product.originalPrice != null) ...[
                              const SizedBox(width: 4),
                              Flexible(
                                child: Text(
                                  '\$${product.originalPrice!.toStringAsFixed(2)}',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    color: Color(0xFF94A3B8),
                                    fontSize: 10,
                                    decoration: TextDecoration.lineThrough,
                                  ),
                                ),
                              ),
                            ],
                            const Spacer(),
                            Text(
                              product.unit,
                              style: const TextStyle(
                                color: _catMuted,
                                fontSize: 11,
                                fontWeight: FontWeight.w500,
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
                            fontSize: 13.5,
                            fontWeight: FontWeight.w700,
                            color: _catTitle,
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
                compact: true,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
