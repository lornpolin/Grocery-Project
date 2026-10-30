import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/product.dart';
import '../../providers/app_providers.dart';
import '../constants/app_colors.dart';
import 'product_stock_badge.dart';

/// Animated overhanging pill button that morphs smoothly between:
/// - "Out of Stock" pill (when stockQuantity <= 0 and quantity == 0)
/// - "+ Add" button (when quantity == 0 and in stock)
/// - "(-)  1  (+)" quantity stepper pill (when quantity >= 1 in the cart)
class ProductAddStepperPill extends ConsumerStatefulWidget {
  final Product product;
  final bool compact;
  final VoidCallback? onFirstAdd;

  const ProductAddStepperPill({
    super.key,
    required this.product,
    this.compact = false,
    this.onFirstAdd,
  });

  @override
  ConsumerState<ProductAddStepperPill> createState() =>
      _ProductAddStepperPillState();
}

class _ProductAddStepperPillState extends ConsumerState<ProductAddStepperPill>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulseController;
  late final Animation<double> _pulseScale;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 180),
    );
    _pulseScale = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.0, end: 1.08)
            .chain(CurveTween(curve: Curves.easeOut)),
        weight: 50,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.08, end: 1.0)
            .chain(CurveTween(curve: Curves.easeIn)),
        weight: 50,
      ),
    ]).animate(_pulseController);
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  void _triggerPulse() {
    _pulseController.forward(from: 0);
  }

  void _handleOutOfStockTap(Product liveProduct) {
    HapticFeedback.heavyImpact();
    showStockAlertMessage(
      context,
      '${liveProduct.name} is currently out of stock',
    );
  }

  Future<void> _handleAdd(Product liveProduct) async {
    if (liveProduct.isOutOfStock) {
      _handleOutOfStockTap(liveProduct);
      return;
    }
    HapticFeedback.lightImpact();
    _triggerPulse();
    final err = await ref.read(cartProvider.notifier).addToCart(liveProduct);
    if (!mounted) return;
    if (err != null) {
      showStockAlertMessage(context, err);
    } else {
      widget.onFirstAdd?.call();
    }
  }

  Future<void> _handleIncrement(Product liveProduct, int currentQty) async {
    if (liveProduct.isOutOfStock) {
      _handleOutOfStockTap(liveProduct);
      return;
    }
    if (currentQty >= liveProduct.stockQuantity) {
      HapticFeedback.heavyImpact();
      showStockAlertMessage(
        context,
        'Only ${liveProduct.stockQuantity} left in stock for ${liveProduct.name}',
      );
      return;
    }
    HapticFeedback.selectionClick();
    _triggerPulse();
    final err = await ref
        .read(cartProvider.notifier)
        .updateQuantity(liveProduct.id, currentQty + 1);
    if (!mounted) return;
    if (err != null) {
      showStockAlertMessage(context, err);
    }
  }

  Future<void> _handleDecrement(Product liveProduct, int currentQty) async {
    HapticFeedback.selectionClick();
    _triggerPulse();
    await ref
        .read(cartProvider.notifier)
        .updateQuantity(liveProduct.id, currentQty - 1);
  }

  @override
  Widget build(BuildContext context) {
    final catalog = ref.watch(productsProvider);
    Product liveProduct = widget.product;
    for (final p in catalog) {
      if (p.id == widget.product.id) {
        liveProduct = p;
        break;
      }
    }

    final cartItems = ref.watch(cartProvider);
    int quantity = 0;
    for (final item in cartItems) {
      if (item.product.id == liveProduct.id) {
        quantity = item.quantity;
        break;
      }
    }

    final isAdded = quantity > 0;
    final isOutOfStock = liveProduct.isOutOfStock && !isAdded;
    final reachedMaxStock =
        isAdded && quantity >= liveProduct.stockQuantity;

    final pillHeight = widget.compact ? 32.0 : 34.0;
    final expandedWidth = widget.compact ? 106.0 : 114.0;
    final collapsedWidth = isOutOfStock
        ? (widget.compact ? 94.0 : 102.0)
        : (widget.compact ? 76.0 : 84.0);
    final circleSize = widget.compact ? 22.0 : 24.0;

    return ScaleTransition(
      scale: _pulseScale,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 260),
        curve: Curves.easeOutBack,
        width: isAdded ? expandedWidth : collapsedWidth,
        height: pillHeight,
        decoration: BoxDecoration(
          color: isOutOfStock ? const Color(0xFFE2E8F0) : AppColors.primary,
          borderRadius: BorderRadius.circular(pillHeight / 2),
          boxShadow: isOutOfStock
              ? null
              : [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.35),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ],
        ),
        child: Material(
          color: Colors.transparent,
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 200),
            switchInCurve: Curves.easeOut,
            switchOutCurve: Curves.easeIn,
            transitionBuilder: (child, animation) {
              return FadeTransition(
                opacity: animation,
                child: ScaleTransition(
                  scale: Tween<double>(begin: 0.9, end: 1.0).animate(animation),
                  child: child,
                ),
              );
            },
            child: isAdded
                ? Padding(
                    key: const ValueKey('stepper'),
                    padding: const EdgeInsets.symmetric(horizontal: 5),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _CircleStepIconButton(
                          size: circleSize,
                          icon: Icons.remove_rounded,
                          onTap: () => _handleDecrement(liveProduct, quantity),
                        ),
                        Expanded(
                          child: Center(
                            child: AnimatedSwitcher(
                              duration: const Duration(milliseconds: 180),
                              transitionBuilder: (child, anim) {
                                return ScaleTransition(
                                  scale: anim,
                                  child: FadeTransition(
                                    opacity: anim,
                                    child: child,
                                  ),
                                );
                              },
                              child: Text(
                                '$quantity',
                                key: ValueKey<int>(quantity),
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w800,
                                  fontSize: widget.compact ? 13.5 : 14.5,
                                ),
                              ),
                            ),
                          ),
                        ),
                        _CircleStepIconButton(
                          size: circleSize,
                          icon: Icons.add_rounded,
                          dimmed: reachedMaxStock,
                          onTap: () => _handleIncrement(liveProduct, quantity),
                        ),
                      ],
                    ),
                  )
                : isOutOfStock
                    ? InkWell(
                        key: const ValueKey('out_of_stock_btn'),
                        borderRadius: BorderRadius.circular(pillHeight / 2),
                        onTap: () => _handleOutOfStockTap(liveProduct),
                        child: Center(
                          child: Text(
                            'Out of Stock',
                            style: TextStyle(
                              color: const Color(0xFF64748B),
                              fontWeight: FontWeight.w700,
                              fontSize: widget.compact ? 11.0 : 11.5,
                            ),
                          ),
                        ),
                      )
                    : InkWell(
                        key: const ValueKey('add_btn'),
                        borderRadius: BorderRadius.circular(pillHeight / 2),
                        onTap: () => _handleAdd(liveProduct),
                        child: Center(
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.add_circle_outline,
                                color: Colors.white,
                                size: widget.compact ? 15 : 16,
                              ),
                              const SizedBox(width: 5),
                              Text(
                                'Add',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600,
                                  fontSize: widget.compact ? 12.5 : 13,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
          ),
        ),
      ),
    );
  }
}

class _CircleStepIconButton extends StatelessWidget {
  final double size;
  final IconData icon;
  final VoidCallback onTap;
  final bool dimmed;

  const _CircleStepIconButton({
    required this.size,
    required this.icon,
    required this.onTap,
    this.dimmed = false,
  });

  @override
  Widget build(BuildContext context) {
    final color =
        dimmed ? Colors.white.withValues(alpha: 0.45) : Colors.white;
    return InkResponse(
      onTap: onTap,
      radius: size * 0.75,
      child: Container(
        width: size,
        height: size,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(
            color: color,
            width: 1.6,
          ),
        ),
        child: Icon(
          icon,
          color: color,
          size: size * 0.68,
        ),
      ),
    );
  }
}
