import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../models/cart_item.dart';
import '../../../models/order.dart';
import '../../../models/product.dart';
import '../../../providers/app_providers.dart';
import '../../../services/api_client.dart';
import '../../cart/widgets/checkout_widgets.dart';

class OrderStatusStyle {
  final String label;
  final String headline;
  final String subtitle;
  final Color fg;
  final Color bg;
  final IconData icon;
  final int stepIndex; // 0: pending, 1: confirmed, 2: delivering, 3: delivered, -1: cancelled

  const OrderStatusStyle({
    required this.label,
    required this.headline,
    required this.subtitle,
    required this.fg,
    required this.bg,
    required this.icon,
    required this.stepIndex,
  });

  static OrderStatusStyle of(String rawStatus) {
    final s = rawStatus.trim().toLowerCase();
    switch (s) {
      case 'delivered':
      case 'completed':
        return const OrderStatusStyle(
          label: 'Delivered',
          headline: 'Order Delivered',
          subtitle: 'Your groceries were delivered to your address.',
          fg: Color(0xFF059669),
          bg: Color(0xFFECFDF5),
          icon: Icons.check_circle_rounded,
          stepIndex: 3,
        );
      case 'delivering':
        return const OrderStatusStyle(
          label: 'Delivering',
          headline: 'Out for Delivery',
          subtitle: 'Your rider is on the way with your order.',
          fg: AppColors.primaryDark,
          bg: AppColors.primaryLight,
          icon: Icons.local_shipping_rounded,
          stepIndex: 2,
        );
      case 'confirmed':
        return const OrderStatusStyle(
          label: 'Confirmed',
          headline: 'Order Confirmed',
          subtitle: 'The store is preparing your items.',
          fg: AppColors.primaryDark,
          bg: AppColors.primaryLight,
          icon: Icons.inventory_2_rounded,
          stepIndex: 1,
        );
      case 'cancelled':
      case 'canceled':
        return const OrderStatusStyle(
          label: 'Cancelled',
          headline: 'Order Cancelled',
          subtitle: 'This order was cancelled.',
          fg: Color(0xFFDC2626),
          bg: Color(0xFFFEF2F2),
          icon: Icons.cancel_rounded,
          stepIndex: -1,
        );
      case 'pending':
      default:
        return const OrderStatusStyle(
          label: 'Pending',
          headline: 'Order Placed',
          subtitle: 'Waiting for the store to confirm your order.',
          fg: Color(0xFFD97706),
          bg: Color(0xFFFFFBEB),
          icon: Icons.schedule_rounded,
          stepIndex: 0,
        );
    }
  }
}

String formatOrderDateTime(DateTime d) {
  const months = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];
  final local = d.toLocal();
  final h = local.hour % 12 == 0 ? 12 : local.hour % 12;
  final min = local.minute.toString().padLeft(2, '0');
  final period = local.hour < 12 ? 'AM' : 'PM';
  return '${local.day} ${months[local.month - 1]} ${local.year}, $h:$min $period';
}

class OrderDetailsScreen extends ConsumerStatefulWidget {
  final Order initialOrder;

  const OrderDetailsScreen({
    super.key,
    required this.initialOrder,
  });

  @override
  ConsumerState<OrderDetailsScreen> createState() => _OrderDetailsScreenState();
}

class _OrderDetailsScreenState extends ConsumerState<OrderDetailsScreen> {
  bool _reordering = false;

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      ref.read(ordersProvider.notifier).refreshOrder(widget.initialOrder.id);
    });
  }

  Product _resolveProduct(Product itemProduct, List<Product> catalog) {
    for (final p in catalog) {
      if (p.id == itemProduct.id) {
        return p;
      }
    }
    return itemProduct;
  }

  Future<void> _reorder(Order order, List<Product> catalog) async {
    if (_reordering) return;
    setState(() => _reordering = true);
    try {
      final cartNotifier = ref.read(cartProvider.notifier);
      for (final item in order.items) {
        final product = _resolveProduct(item.product, catalog);
        await cartNotifier.addToCart(product, quantity: item.quantity);
      }
      if (!mounted) return;
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Text(
              'Added ${order.itemCount} item${order.itemCount == 1 ? '' : 's'} from Order #${order.id} to your cart',
            ),
            behavior: SnackBarBehavior.floating,
          ),
        );
      context.push('/cart');
    } finally {
      if (mounted) {
        setState(() => _reordering = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final orders = ref.watch(ordersProvider);
    final catalog = ref.watch(productsProvider);
    Order order = widget.initialOrder;
    for (final o in orders) {
      if (o.id == widget.initialOrder.id) {
        order = o;
        break;
      }
    }

    final statusStyle = OrderStatusStyle.of(order.status);

    return Scaffold(
      backgroundColor: CheckoutColors.pageBg,
      appBar: CheckoutAppBar(
        title: 'Order #${order.id}',
        onBack: () => context.canPop() ? context.pop() : context.go('/orders'),
      ),
      body: RefreshIndicator(
        color: AppColors.primary,
        onRefresh: () async {
          await ref.read(ordersProvider.notifier).refreshOrder(order.id);
        },
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
          children: [
            _StatusTimelineCard(
              order: order,
              style: statusStyle,
            ),
            const SizedBox(height: 14),
            _OrderItemsCard(
              items: order.items,
              catalog: catalog,
              resolveProduct: _resolveProduct,
            ),
            const SizedBox(height: 14),
            _DeliveryInfoCard(order: order),
            const SizedBox(height: 14),
            _PaymentBreakdownCard(order: order),
          ],
        ),
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
        decoration: BoxDecoration(
          color: Colors.white,
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
          child: Row(
            children: [
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${order.itemCount} item${order.itemCount == 1 ? '' : 's'} · Total',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: CheckoutColors.muted,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      money(order.total),
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: CheckoutColors.title,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                flex: 2,
                child: SizedBox(
                  height: 52,
                  child: ElevatedButton.icon(
                    onPressed:
                        _reordering ? null : () => _reorder(order, catalog),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(28),
                      ),
                    ),
                    icon: _reordering
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.replay_rounded, size: 20),
                    label: Text(
                      _reordering ? 'Adding to Cart...' : 'Reorder Items',
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatusTimelineCard extends StatelessWidget {
  final Order order;
  final OrderStatusStyle style;

  const _StatusTimelineCard({
    required this.order,
    required this.style,
  });

  static const _steps = [
    (label: 'Placed', icon: Icons.receipt_long_rounded),
    (label: 'Confirmed', icon: Icons.inventory_2_outlined),
    (label: 'Delivering', icon: Icons.local_shipping_outlined),
    (label: 'Delivered', icon: Icons.check_circle_outline_rounded),
  ];

  @override
  Widget build(BuildContext context) {
    return CheckoutCard(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: style.bg,
                  shape: BoxShape.circle,
                ),
                child: Icon(style.icon, color: style.fg, size: 24),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            style.headline,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              color: CheckoutColors.title,
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: style.bg,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            style.label,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: style.fg,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      style.subtitle,
                      style: const TextStyle(
                        fontSize: 13,
                        color: CheckoutColors.muted,
                        height: 1.35,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        const Icon(
                          Icons.calendar_today_outlined,
                          size: 13,
                          color: CheckoutColors.hint,
                        ),
                        const SizedBox(width: 5),
                        Text(
                          formatOrderDateTime(order.createdAt),
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: CheckoutColors.muted,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (style.stepIndex >= 0) ...[
            const SizedBox(height: 20),
            const Divider(height: 1, color: CheckoutColors.line),
            const SizedBox(height: 18),
            Row(
              children: [
                for (int i = 0; i < _steps.length; i++) ...[
                  _StepNode(
                    icon: _steps[i].icon,
                    label: _steps[i].label,
                    isCompleted: i <= style.stepIndex,
                    isCurrent: i == style.stepIndex,
                    activeColor:
                        style.stepIndex == 3 ? style.fg : AppColors.primary,
                  ),
                  if (i < _steps.length - 1)
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.only(bottom: 20),
                        child: Container(
                          height: 2.5,
                          decoration: BoxDecoration(
                            color: i < style.stepIndex
                                ? (style.stepIndex == 3
                                    ? style.fg
                                    : AppColors.primary)
                                : CheckoutColors.line,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ),
                    ),
                ],
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _StepNode extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isCompleted;
  final bool isCurrent;
  final Color activeColor;

  const _StepNode({
    required this.icon,
    required this.label,
    required this.isCompleted,
    required this.isCurrent,
    required this.activeColor,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isCompleted ? activeColor : const Color(0xFFF1F5F9),
            boxShadow: isCurrent
                ? [
                    BoxShadow(
                      color: activeColor.withValues(alpha: 0.28),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ]
                : null,
          ),
          child: Icon(
            icon,
            size: 17,
            color: isCompleted ? Colors.white : CheckoutColors.hint,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: isCompleted ? FontWeight.w700 : FontWeight.w500,
            color: isCompleted ? CheckoutColors.title : CheckoutColors.hint,
          ),
        ),
      ],
    );
  }
}

class _OrderItemsCard extends StatelessWidget {
  final List<CartItem> items;
  final List<Product> catalog;
  final Product Function(Product, List<Product>) resolveProduct;

  const _OrderItemsCard({
    required this.items,
    required this.catalog,
    required this.resolveProduct,
  });

  @override
  Widget build(BuildContext context) {
    final totalQty = items.fold<int>(0, (sum, i) => sum + i.quantity);

    return CheckoutCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.shopping_bag_outlined,
                size: 18,
                color: AppColors.primary,
              ),
              const SizedBox(width: 8),
              const Text(
                'Order Items',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: CheckoutColors.title,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.primaryLight,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '$totalQty item${totalQty == 1 ? '' : 's'}',
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primaryDark,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Divider(height: 1, color: CheckoutColors.line),
          for (int i = 0; i < items.length; i++) ...[
            if (i > 0) const Divider(height: 1, color: CheckoutColors.line),
            _OrderItemRow(
              item: items[i],
              product: resolveProduct(items[i].product, catalog),
            ),
          ],
        ],
      ),
    );
  }
}

class _OrderItemRow extends StatelessWidget {
  final CartItem item;
  final Product product;

  const _OrderItemRow({
    required this.item,
    required this.product,
  });

  @override
  Widget build(BuildContext context) {
    final imageUrl = product.imageUrl.isNotEmpty
        ? ApiClient.instance.resolveStorageUrl(product.imageUrl)
        : '';

    return InkWell(
      borderRadius: BorderRadius.circular(10),
      onTap: product.id.isNotEmpty
          ? () => context.push(
                '/product-details?id=${product.id}',
                extra: product,
              )
          : null,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: CheckoutColors.line),
              ),
              clipBehavior: Clip.antiAlias,
              child: imageUrl.isNotEmpty
                  ? Image.network(
                      imageUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (_, _, _) => const Icon(
                        Icons.fastfood_outlined,
                        color: CheckoutColors.hint,
                        size: 24,
                      ),
                    )
                  : const Icon(
                      Icons.fastfood_outlined,
                      color: CheckoutColors.hint,
                      size: 24,
                    ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.product.name.isNotEmpty
                        ? item.product.name
                        : product.name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: CheckoutColors.title,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${money(item.product.price)} × ${item.quantity}',
                    style: const TextStyle(
                      fontSize: 12,
                      color: CheckoutColors.muted,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  money(item.subtotal),
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: CheckoutColors.title,
                  ),
                ),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    'Qty: ${item.quantity}',
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: CheckoutColors.label,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _DeliveryInfoCard extends StatelessWidget {
  final Order order;

  const _DeliveryInfoCard({required this.order});

  @override
  Widget build(BuildContext context) {
    return CheckoutCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(
                Icons.local_shipping_outlined,
                size: 18,
                color: AppColors.primary,
              ),
              SizedBox(width: 8),
              Text(
                'Delivery Details',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: CheckoutColors.title,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Divider(height: 1, color: CheckoutColors.line),
          const SizedBox(height: 12),
          _InfoTile(
            icon: Icons.location_on_outlined,
            label: 'Delivery Address',
            value: order.address,
          ),
          const SizedBox(height: 12),
          _InfoTile(
            icon: Icons.payments_outlined,
            label: 'Payment Method',
            value: order.paymentMethod,
          ),
          if (order.instructions.trim().isNotEmpty) ...[
            const SizedBox(height: 12),
            _InfoTile(
              icon: Icons.notes_rounded,
              label: 'Delivery Instructions',
              value: order.instructions,
            ),
          ],
        ],
      ),
    );
  }
}

class _InfoTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _InfoTile({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: AppColors.primaryLight,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, size: 18, color: AppColors.primary),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 12,
                  color: CheckoutColors.muted,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: CheckoutColors.title,
                  height: 1.35,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _PaymentBreakdownCard extends StatelessWidget {
  final Order order;

  const _PaymentBreakdownCard({required this.order});

  @override
  Widget build(BuildContext context) {
    return CheckoutCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(
                Icons.receipt_outlined,
                size: 18,
                color: AppColors.primary,
              ),
              SizedBox(width: 8),
              Text(
                'Payment Summary',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: CheckoutColors.title,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Divider(height: 1, color: CheckoutColors.line),
          const SizedBox(height: 10),
          SummaryRow(label: 'Subtotal', amount: order.subtotal),
          SummaryRow(label: 'Delivery Fee', amount: order.deliveryFee),
          if (order.serviceFee > 0)
            SummaryRow(label: 'Service Fee', amount: order.serviceFee),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 8),
            child: Divider(height: 1, color: CheckoutColors.line),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Total Paid',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: CheckoutColors.title,
                ),
              ),
              Text(
                money(order.total),
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

