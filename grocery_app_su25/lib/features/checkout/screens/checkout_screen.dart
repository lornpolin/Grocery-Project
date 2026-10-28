import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../providers/app_providers.dart';
import '../../cart/widgets/checkout_widgets.dart';

enum PaymentMethod {
  cash('Cash', Icons.payments_outlined),
  khqr('KHQR', Icons.qr_code_2_rounded),
  card('Credit / Debit Card', Icons.credit_card_rounded);

  final String label;
  final IconData icon;
  const PaymentMethod(this.label, this.icon);
}

/// Step 3 of the order flow: delivery address, payment and place order.
class CheckoutScreen extends ConsumerStatefulWidget {
  const CheckoutScreen({super.key});

  @override
  ConsumerState<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends ConsumerState<CheckoutScreen> {
  String _address = '83 Street 7B, Phnom Penh';
  PaymentMethod _payment = PaymentMethod.cash;
  final _instructions = TextEditingController();

  @override
  void dispose() {
    _instructions.dispose();
    super.dispose();
  }

  Future<void> _editAddress() async {
    final controller = TextEditingController(text: _address);
    final result = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        title: const Text('Delivery address',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
        content: TextField(
          controller: controller,
          autofocus: true,
          maxLines: 2,
          minLines: 1,
          decoration: const InputDecoration(hintText: 'Street, city'),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          TextButton(
              onPressed: () => Navigator.pop(ctx, controller.text.trim()),
              child: const Text('Save')),
        ],
      ),
    );
    controller.dispose();
    if (result != null && result.isNotEmpty) setState(() => _address = result);
  }

  Future<void> _changePayment() async {
    final result = await showModalBottomSheet<PaymentMethod>(
      context: context,
      backgroundColor: Colors.white,
      showDragHandle: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Padding(
                padding: EdgeInsets.only(left: 4, bottom: 8),
                child: Text('Payment method',
                    style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: CheckoutColors.title)),
              ),
              for (final m in PaymentMethod.values)
                ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 4),
                  leading: Icon(m.icon,
                      color: m == _payment
                          ? AppColors.primary
                          : CheckoutColors.muted),
                  title: Text(m.label,
                      style: const TextStyle(
                          fontSize: 15, color: CheckoutColors.title)),
                  trailing: m == _payment
                      ? const Icon(Icons.check_circle_rounded,
                          color: AppColors.primary)
                      : const Icon(Icons.circle_outlined,
                          color: CheckoutColors.line),
                  onTap: () => Navigator.pop(ctx, m),
                ),
            ],
          ),
        ),
      ),
    );
    if (result != null) setState(() => _payment = result);
  }

  Future<void> _placeOrder(double subtotal) async {
    final items = ref.read(cartProvider);
    final order = await ref.read(ordersProvider.notifier).placeOrder(
          items: items,
          subtotal: subtotal,
          address: _address,
          instructions: _instructions.text.trim(),
          paymentMethod: _payment.label,
        );
    await ref.read(cartProvider.notifier).clearCart();
    ref.read(productsProvider.notifier).refresh();
    if (!mounted) return;

    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 28, 24, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 76,
                height: 76,
                decoration: const BoxDecoration(
                    color: AppColors.primaryLight, shape: BoxShape.circle),
                child: const Icon(Icons.check_rounded,
                    size: 42, color: AppColors.primary),
              ),
              const SizedBox(height: 18),
              const Text('Order placed!',
                  style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: CheckoutColors.title)),
              const SizedBox(height: 8),
              Text(
                'Order #${order.id} · ${money(order.total)}\nWe\'ll deliver it to $_address.',
                textAlign: TextAlign.center,
                style: const TextStyle(
                    fontSize: 14, height: 1.5, color: CheckoutColors.muted),
              ),
              const SizedBox(height: 22),
              PillButton(
                label: 'View my orders',
                onPressed: () => Navigator.pop(ctx),
              ),
            ],
          ),
        ),
      ),
    );
    if (mounted) context.go('/orders');
  }

  @override
  Widget build(BuildContext context) {
    final subtotal = ref.watch(cartTotalProvider);
    final hasItems = ref.watch(cartProvider).isNotEmpty;
    final total = subtotal + kDeliveryFee + kServiceFee;

    return Scaffold(
      backgroundColor: CheckoutColors.pageBg,
      appBar: CheckoutAppBar(title: 'Checkout', onBack: () => context.pop()),
      body: ListView(
        padding: const EdgeInsets.only(bottom: 24),
        children: [
          const CheckoutStepper(current: 3),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _addressCard(),
                const SizedBox(height: 22),
                Row(
                  children: [
                    const Text('Payment Method',
                        style: TextStyle(
                            fontSize: 19,
                            fontWeight: FontWeight.w800,
                            color: CheckoutColors.title)),
                    const Spacer(),
                    GestureDetector(
                      onTap: _changePayment,
                      child: const Text('Change',
                          style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: AppColors.primary,
                              decoration: TextDecoration.underline,
                              decorationColor: AppColors.primary)),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                CheckoutCard(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
                  child: Row(
                    children: [
                      Icon(_payment.icon, color: CheckoutColors.muted, size: 24),
                      const SizedBox(width: 12),
                      Text(_payment.label,
                          style: const TextStyle(
                              fontSize: 16, color: CheckoutColors.label)),
                      const Spacer(),
                      Text(money(total),
                          style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                              color: CheckoutColors.label)),
                    ],
                  ),
                ),
                const SizedBox(height: 22),
                CheckoutCard(
                  child: Column(
                    children: [
                      SummaryRow(
                          label: 'Subtotal', amount: subtotal, emphasized: true),
                      const SummaryRow(
                          label: 'Delivery Charge', amount: kDeliveryFee),
                      const SummaryRow(label: 'Service Fee', amount: kServiceFee),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 12,
                offset: const Offset(0, -4)),
          ],
        ),
        child: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TotalWithVoucher(total: total),
                const SizedBox(height: 14),
                PillButton(
                  label: 'Place Order',
                  onPressed: hasItems ? () => _placeOrder(subtotal) : null,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _addressCard() {
    return CheckoutCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.location_on_outlined,
                  size: 24, color: CheckoutColors.title),
              const SizedBox(width: 6),
              const Text('Delivery Address',
                  style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: CheckoutColors.title)),
              const Spacer(),
              InkResponse(
                onTap: _editAddress,
                radius: 20,
                child: const Icon(Icons.edit_square,
                    size: 22, color: CheckoutColors.title),
              ),
            ],
          ),
          const SizedBox(height: 14),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: Image.asset(
              'assets/images/delivery_map.png',
              height: 132,
              width: double.infinity,
              fit: BoxFit.cover,
            ),
          ),
          const SizedBox(height: 14),
          Text(_address,
              style: const TextStyle(fontSize: 15, color: CheckoutColors.title)),
          const SizedBox(height: 14),
          TextField(
            controller: _instructions,
            style: const TextStyle(fontSize: 13),
            decoration: InputDecoration(
              labelText: 'Delivery instructions',
              hintText: 'Floor or Apt No or tell us how we can find you',
              floatingLabelBehavior: FloatingLabelBehavior.always,
              labelStyle:
                  const TextStyle(fontSize: 13, color: CheckoutColors.muted),
              hintStyle:
                  const TextStyle(fontSize: 12, color: CheckoutColors.hint),
              isDense: true,
              filled: false,
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: CheckoutColors.line),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: AppColors.primary),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
