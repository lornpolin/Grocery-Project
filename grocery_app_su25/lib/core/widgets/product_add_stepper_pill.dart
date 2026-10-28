import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/product.dart';
import '../../providers/app_providers.dart';
import '../constants/app_colors.dart';

/// Animated overhanging pill button that morphs smoothly between an "+ Add"
/// button (when quantity == 0) and a "(-)  1  (+)" quantity stepper pill
/// (when quantity >= 1 in the cart).
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

  void _handleAdd() {
    HapticFeedback.lightImpact();
    _triggerPulse();
    ref.read(cartProvider.notifier).addToCart(widget.product);
    widget.onFirstAdd?.call();
  }

  void _handleIncrement(int currentQty) {
    HapticFeedback.selectionClick();
    _triggerPulse();
    ref
        .read(cartProvider.notifier)
        .updateQuantity(widget.product.id, currentQty + 1);
  }

  void _handleDecrement(int currentQty) {
    HapticFeedback.selectionClick();
    _triggerPulse();
    ref
        .read(cartProvider.notifier)
        .updateQuantity(widget.product.id, currentQty - 1);
  }

  @override
  Widget build(BuildContext context) {
    final cartItems = ref.watch(cartProvider);
    int quantity = 0;
    for (final item in cartItems) {
      if (item.product.id == widget.product.id) {
        quantity = item.quantity;
        break;
      }
    }

    final isAdded = quantity > 0;
    final pillHeight = widget.compact ? 32.0 : 34.0;
    final expandedWidth = widget.compact ? 106.0 : 114.0;
    final collapsedWidth = widget.compact ? 76.0 : 84.0;
    final circleSize = widget.compact ? 22.0 : 24.0;

    return ScaleTransition(
      scale: _pulseScale,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 260),
        curve: Curves.easeOutBack,
        width: isAdded ? expandedWidth : collapsedWidth,
        height: pillHeight,
        decoration: BoxDecoration(
          color: AppColors.primary,
          borderRadius: BorderRadius.circular(pillHeight / 2),
          boxShadow: [
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
                          onTap: () => _handleDecrement(quantity),
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
                          onTap: () => _handleIncrement(quantity),
                        ),
                      ],
                    ),
                  )
                : InkWell(
                    key: const ValueKey('add_btn'),
                    borderRadius: BorderRadius.circular(pillHeight / 2),
                    onTap: _handleAdd,
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

  const _CircleStepIconButton({
    required this.size,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
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
            color: Colors.white,
            width: 1.6,
          ),
        ),
        child: Icon(
          icon,
          color: Colors.white,
          size: size * 0.68,
        ),
      ),
    );
  }
}

