import 'package:flutter/material.dart';

/// Animated shimmer box used for skeleton loading states.
class ShimmerBox extends StatefulWidget {
  final double? width;
  final double? height;
  final BorderRadiusGeometry borderRadius;
  final BoxShape shape;

  const ShimmerBox({
    super.key,
    this.width,
    this.height,
    this.borderRadius = const BorderRadius.all(Radius.circular(8)),
    this.shape = BoxShape.rectangle,
  });

  @override
  State<ShimmerBox> createState() => _ShimmerBoxState();
}

class _ShimmerBoxState extends State<ShimmerBox>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1300),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        final slide = (_controller.value * 3.0) - 1.0;
        return Container(
          width: widget.width,
          height: widget.height,
          decoration: BoxDecoration(
            shape: widget.shape,
            borderRadius:
                widget.shape == BoxShape.rectangle ? widget.borderRadius : null,
            gradient: LinearGradient(
              begin: Alignment(slide - 1.0, -0.2),
              end: Alignment(slide + 1.0, 0.2),
              colors: const [
                Color(0xFFE9EEF5),
                Color(0xFFF6F8FB),
                Color(0xFFE9EEF5),
              ],
              stops: const [0.1, 0.5, 0.9],
            ),
          ),
        );
      },
    );
  }
}

/// 4x2 category grid skeleton for HomeScreen's Categories panel.
class HomeCategoryGridSkeleton extends StatelessWidget {
  final int itemCount;

  const HomeCategoryGridSkeleton({super.key, this.itemCount = 8});

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      crossAxisCount: 4,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 12,
      crossAxisSpacing: 8,
      childAspectRatio: 0.82,
      children: List.generate(
        itemCount,
        (_) => const Column(
          children: [
            ShimmerBox(
              width: 60,
              height: 60,
              borderRadius: BorderRadius.all(Radius.circular(16)),
            ),
            SizedBox(height: 8),
            ShimmerBox(
              width: 48,
              height: 11,
              borderRadius: BorderRadius.all(Radius.circular(6)),
            ),
          ],
        ),
      ),
    );
  }
}

/// Skeleton matching [ProductTile] on the HomeScreen horizontal carousel.
class ProductTileSkeleton extends StatelessWidget {
  const ProductTileSkeleton({super.key});

  static const double cardHeight = 212;
  static const double buttonOverhang = 14;
  static const double width = 164;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
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
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ShimmerBox(
                    width: double.infinity,
                    height: 140,
                    borderRadius: BorderRadius.vertical(
                      top: Radius.circular(16),
                    ),
                  ),
                  Padding(
                    padding: EdgeInsets.fromLTRB(12, 10, 12, 0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            ShimmerBox(
                              width: 54,
                              height: 14,
                              borderRadius:
                                  BorderRadius.all(Radius.circular(6)),
                            ),
                            ShimmerBox(
                              width: 34,
                              height: 11,
                              borderRadius:
                                  BorderRadius.all(Radius.circular(6)),
                            ),
                          ],
                        ),
                        SizedBox(height: 8),
                        ShimmerBox(
                          width: 112,
                          height: 14,
                          borderRadius: BorderRadius.all(Radius.circular(6)),
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
              child: Container(
                padding: const EdgeInsets.all(2),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                ),
                child: const ShimmerBox(
                  width: 82,
                  height: 28,
                  borderRadius: BorderRadius.all(Radius.circular(16)),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Skeleton item for the left category rail on CategoriesScreen.
class SidebarCategoryTileSkeleton extends StatelessWidget {
  const SidebarCategoryTileSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return const Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        ShimmerBox(
          width: 54,
          height: 54,
          borderRadius: BorderRadius.all(Radius.circular(16)),
        ),
        SizedBox(height: 6),
        ShimmerBox(
          width: 46,
          height: 10,
          borderRadius: BorderRadius.all(Radius.circular(5)),
        ),
      ],
    );
  }
}

/// 2-column grid skeleton matching [_CategoryProductCard] on CategoriesScreen.
class CategoryProductGridSkeleton extends StatelessWidget {
  final int itemCount;

  const CategoryProductGridSkeleton({super.key, this.itemCount = 6});

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisExtent: 218,
        crossAxisSpacing: 10,
        mainAxisSpacing: 16,
      ),
      itemCount: itemCount,
      itemBuilder: (_, _) => const _CategoryProductCardSkeleton(),
    );
  }
}

class _CategoryProductCardSkeleton extends StatelessWidget {
  const _CategoryProductCardSkeleton();

  static const double _cardHeight = 204;

  @override
  Widget build(BuildContext context) {
    return Stack(
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
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 10,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ShimmerBox(
                  width: double.infinity,
                  height: 132,
                  borderRadius: BorderRadius.vertical(
                    top: Radius.circular(16),
                  ),
                ),
                Padding(
                  padding: EdgeInsets.fromLTRB(10, 10, 10, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          ShimmerBox(
                            width: 48,
                            height: 13,
                            borderRadius: BorderRadius.all(Radius.circular(6)),
                          ),
                          ShimmerBox(
                            width: 30,
                            height: 10,
                            borderRadius: BorderRadius.all(Radius.circular(5)),
                          ),
                        ],
                      ),
                      SizedBox(height: 7),
                      ShimmerBox(
                        width: 96,
                        height: 13,
                        borderRadius: BorderRadius.all(Radius.circular(6)),
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
            child: Container(
              padding: const EdgeInsets.all(2),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
              ),
              child: const ShimmerBox(
                width: 76,
                height: 26,
                borderRadius: BorderRadius.all(Radius.circular(16)),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

