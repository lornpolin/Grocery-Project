import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/widgets/product_stock_badge.dart';
import '../../../models/order.dart';
import '../../../models/product.dart';
import '../../../providers/app_providers.dart';
import '../../../services/api_client.dart';
import '../../cart/widgets/checkout_widgets.dart';
import 'order_details_screen.dart';

const _ordersBg = Color(0xFFF8FAFC);
const _ordersTitle = Color(0xFF0F172A);
const _ordersMuted = Color(0xFF64748B);

enum _OrderFilter { all, active, delivered, cancelled }

class OrdersScreen extends ConsumerStatefulWidget {
  const OrdersScreen({super.key});

  @override
  ConsumerState<OrdersScreen> createState() => _OrdersScreenState();
}

class _OrdersScreenState extends ConsumerState<OrdersScreen> {
  _OrderFilter _filter = _OrderFilter.all;

  bool _matches(Order order, _OrderFilter filter) {
    final s = order.status.trim().toLowerCase();
    switch (filter) {
      case _OrderFilter.all:
        return true;
      case _OrderFilter.active:
        return s == 'pending' || s == 'confirmed' || s == 'delivering';
      case _OrderFilter.delivered:
        return s == 'delivered' || s == 'completed';
      case _OrderFilter.cancelled:
        return s == 'cancelled' || s == 'canceled';
    }
  }

  @override
  Widget build(BuildContext context) {
    final orders = ref.watch(ordersProvider);
    final catalog = ref.watch(productsProvider);
    final filtered = orders.where((o) => _matches(o, _filter)).toList();

    return Scaffold(
      backgroundColor: _ordersBg,
      appBar: AppBar(
        backgroundColor: _ordersBg,
        surfaceTintColor: Colors.transparent,
        centerTitle: true,
        title: const Text(
          'My Orders',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: _ordersTitle,
          ),
        ),
      ),
      body: orders.isEmpty
          ? RefreshIndicator(
              color: AppColors.primary,
              onRefresh: () => ref.read(ordersProvider.notifier).refresh(),
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                children: const [
                  SizedBox(height: 100),
                  _EmptyOrders(),
                ],
              ),
            )
          : Column(
              children: [
                _FilterBar(
                  selected: _filter,
                  orders: orders,
                  matches: _matches,
                  onChanged: (next) => setState(() => _filter = next),
                ),
                Expanded(
                  child: RefreshIndicator(
                    color: AppColors.primary,
                    onRefresh: () =>
                        ref.read(ordersProvider.notifier).refresh(),
                    child: filtered.isEmpty
                        ? ListView(
                            physics: const AlwaysScrollableScrollPhysics(),
                            children: [
                              const SizedBox(height: 90),
                              _EmptyFilteredOrders(
                                onReset: () =>
                                    setState(() => _filter = _OrderFilter.all),
                              ),
                            ],
                          )
                        : ListView.separated(
                            physics: const AlwaysScrollableScrollPhysics(),
                            padding:
                                const EdgeInsets.fromLTRB(16, 8, 16, 110),
                            itemCount: filtered.length,
                            separatorBuilder: (_, _) =>
                                const SizedBox(height: 12),
                            itemBuilder: (_, i) => _OrderCard(
                              order: filtered[i],
                              catalog: catalog,
                            ),
                          ),
                  ),
                ),
              ],
            ),
    );
  }
}

class _FilterBar extends StatelessWidget {
  final _OrderFilter selected;
  final List<Order> orders;
  final bool Function(Order, _OrderFilter) matches;
  final ValueChanged<_OrderFilter> onChanged;

  const _FilterBar({
    required this.selected,
    required this.orders,
    required this.matches,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final tabs = [
      (filter: _OrderFilter.all, label: 'All'),
      (filter: _OrderFilter.active, label: 'Active'),
      (filter: _OrderFilter.delivered, label: 'Delivered'),
      (filter: _OrderFilter.cancelled, label: 'Cancelled'),
    ];

    return SizedBox(
      height: 46,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        scrollDirection: Axis.horizontal,
        itemCount: tabs.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (_, i) {
          final tab = tabs[i];
          final isSelected = selected == tab.filter;
          final count = orders.where((o) => matches(o, tab.filter)).length;

          return InkWell(
            borderRadius: BorderRadius.circular(20),
            onTap: () => onChanged(tab.filter),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: BoxDecoration(
                color: isSelected ? AppColors.primary : Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isSelected ? AppColors.primary : CheckoutColors.line,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    tab.label,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: isSelected ? Colors.white : CheckoutColors.label,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 1,
                    ),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? Colors.white.withValues(alpha: 0.22)
                          : const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      '$count',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: isSelected ? Colors.white : _ordersMuted,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _OrderCard extends ConsumerWidget {
  final Order order;
  final List<Product> catalog;

  const _OrderCard({
    required this.order,
    required this.catalog,
  });

  Product _resolveProduct(Product itemProduct) {
    for (final p in catalog) {
      if (p.id == itemProduct.id) return p;
    }
    return itemProduct;
  }

  void _openDetails(BuildContext context) {
    context.push('/order-details?id=${order.id}', extra: order);
  }

  Future<void> _reorder(BuildContext context, WidgetRef ref) async {
    final cartNotifier = ref.read(cartProvider.notifier);
    int addedItems = 0;
    final stockErrors = <String>[];
    for (final item in order.items) {
      final product = _resolveProduct(item.product);
      final err = await cartNotifier.addToCart(product, quantity: item.quantity);
      if (err == null) {
        addedItems += item.quantity;
      } else {
        stockErrors.add(err);
      }
    }
    if (!context.mounted) return;
    if (addedItems == 0 && stockErrors.isNotEmpty) {
      showStockAlertMessage(context, stockErrors.first);
      return;
    }
    if (stockErrors.isNotEmpty) {
      showStockAlertMessage(
        context,
        'Added available items. ${stockErrors.first}',
      );
      context.push('/cart');
      return;
    }
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(
            'Added $addedItems item${addedItems == 1 ? '' : 's'} to your cart',
          ),
          behavior: SnackBarBehavior.floating,
        ),
      );
    context.push('/cart');
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final names =
        order.items.map((i) => '${i.quantity}× ${i.product.name}').join(', ');
    final statusStyle = OrderStatusStyle.of(order.status);

    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => _openDetails(context),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.03),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: statusStyle.bg,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      statusStyle.icon,
                      size: 18,
                      color: statusStyle.fg,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Order #${order.id}',
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: _ordersTitle,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          formatOrderDateTime(order.createdAt),
                          style: const TextStyle(
                            fontSize: 12,
                            color: _ordersMuted,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: statusStyle.bg,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      statusStyle.label,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: statusStyle.fg,
                      ),
                    ),
                  ),
                ],
              ),
              const Divider(height: 24, color: CheckoutColors.line),
              Row(
                children: [
                  if (order.items.isNotEmpty) ...[
                    _OrderItemsThumbStrip(
                      order: order,
                      resolveProduct: _resolveProduct,
                    ),
                    const SizedBox(width: 10),
                  ],
                  Expanded(
                    child: Text(
                      names,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        height: 1.35,
                        color: CheckoutColors.label,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  const Icon(
                    Icons.location_on_outlined,
                    size: 16,
                    color: _ordersMuted,
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      order.address,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 12,
                        color: _ordersMuted,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Text(
                    '${order.itemCount} item${order.itemCount == 1 ? '' : 's'} · ${order.paymentMethod}',
                    style: const TextStyle(fontSize: 13, color: _ordersMuted),
                  ),
                  const Spacer(),
                  Text(
                    money(order.total),
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                      color: AppColors.primary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: SizedBox(
                      height: 36,
                      child: OutlinedButton(
                        onPressed: () => _openDetails(context),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: _ordersTitle,
                          side: const BorderSide(color: CheckoutColors.line),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(18),
                          ),
                          padding: EdgeInsets.zero,
                        ),
                        child: const Text(
                          'View Details',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: SizedBox(
                      height: 36,
                      child: ElevatedButton.icon(
                        onPressed: () => _reorder(context, ref),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primaryLight,
                          foregroundColor: AppColors.primaryDark,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(18),
                          ),
                          padding: EdgeInsets.zero,
                        ),
                        icon: const Icon(Icons.replay_rounded, size: 15),
                        label: const Text(
                          'Reorder',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _OrderItemsThumbStrip extends StatelessWidget {
  final Order order;
  final Product Function(Product) resolveProduct;

  const _OrderItemsThumbStrip({
    required this.order,
    required this.resolveProduct,
  });

  @override
  Widget build(BuildContext context) {
    final previewItems = order.items.take(2).toList();
    return SizedBox(
      width: previewItems.length == 1 ? 42 : 66,
      height: 42,
      child: Stack(
        children: [
          for (int i = 0; i < previewItems.length; i++)
            Positioned(
              left: i * 24.0,
              child: _ThumbBox(
                product: resolveProduct(previewItems[i].product),
              ),
            ),
        ],
      ),
    );
  }
}

class _ThumbBox extends StatelessWidget {
  final Product product;

  const _ThumbBox({required this.product});

  @override
  Widget build(BuildContext context) {
    final imageUrl = product.imageUrl.isNotEmpty
        ? ApiClient.instance.resolveStorageUrl(product.imageUrl)
        : '';

    return Container(
      width: 42,
      height: 42,
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.white, width: 2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 4,
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: imageUrl.isNotEmpty
          ? Image.network(
              imageUrl,
              fit: BoxFit.cover,
              errorBuilder: (_, _, _) => const Icon(
                Icons.fastfood_outlined,
                size: 18,
                color: CheckoutColors.hint,
              ),
            )
          : const Icon(
              Icons.fastfood_outlined,
              size: 18,
              color: CheckoutColors.hint,
            ),
    );
  }
}

class _EmptyFilteredOrders extends StatelessWidget {
  final VoidCallback onReset;

  const _EmptyFilteredOrders({required this.onReset});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 76,
              height: 76,
              decoration: const BoxDecoration(
                color: AppColors.primaryLight,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.filter_list_rounded,
                size: 36,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'No matching orders',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w700,
                color: _ordersTitle,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'There are no orders with this status yet.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: _ordersMuted),
            ),
            const SizedBox(height: 16),
            TextButton(
              onPressed: onReset,
              child: const Text(
                'Show all orders',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  color: AppColors.primary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyOrders extends StatelessWidget {
  const _EmptyOrders();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(32, 0, 32, 96),
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
                Icons.assignment_outlined,
                size: 52,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'No orders yet',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: _ordersTitle,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'When you place an order, it will show up here so you can track it.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, height: 1.5, color: _ordersMuted),
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
