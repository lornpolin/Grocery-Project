import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../models/address.dart';
import '../../../providers/app_providers.dart';
import '../../addresses/screens/addresses_screen.dart';
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
  PaymentMethod _payment = PaymentMethod.cash;
  final _instructions = TextEditingController();

  @override
  void dispose() {
    _instructions.dispose();
    super.dispose();
  }

  Future<void> _selectOrEditAddress(
    List<SavedAddress> addresses,
    SavedAddress? current,
  ) async {
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.white,
      showDragHandle: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Text(
                    'Delivery Address',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: CheckoutColors.title,
                    ),
                  ),
                  const Spacer(),
                  TextButton.icon(
                    onPressed: () {
                      Navigator.pop(ctx);
                      context.push('/addresses');
                    },
                    icon: const Icon(Icons.add_rounded, size: 18),
                    label: const Text('Manage'),
                  ),
                ],
              ),
              if (addresses.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 12),
                  child: Text(
                    'No saved address yet. Add your delivery address to continue.',
                    style: TextStyle(
                      fontSize: 14,
                      color: CheckoutColors.muted,
                    ),
                  ),
                )
              else
                ConstrainedBox(
                  constraints: const BoxConstraints(maxHeight: 280),
                  child: ListView.separated(
                    shrinkWrap: true,
                    itemCount: addresses.length,
                    separatorBuilder: (_, _) =>
                        const Divider(height: 1, color: CheckoutColors.line),
                    itemBuilder: (_, index) {
                      final a = addresses[index];
                      final isSelected = current?.id == a.id;
                      return ListTile(
                        contentPadding:
                            const EdgeInsets.symmetric(horizontal: 4),
                        leading: Icon(
                          iconForAddressLabel(a.label),
                          color: isSelected
                              ? AppColors.primary
                              : CheckoutColors.muted,
                        ),
                        title: Text(
                          a.label,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: CheckoutColors.title,
                          ),
                        ),
                        subtitle: Text(
                          a.fullAddress,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 13,
                            color: CheckoutColors.muted,
                          ),
                        ),
                        trailing: isSelected
                            ? const Icon(
                                Icons.check_circle_rounded,
                                color: AppColors.primary,
                              )
                            : const Icon(
                                Icons.circle_outlined,
                                color: CheckoutColors.line,
                              ),
                        onTap: () {
                          ref
                              .read(addressesProvider.notifier)
                              .setDefault(a.id);
                          Navigator.pop(ctx);
                        },
                      );
                    },
                  ),
                ),
              const SizedBox(height: 12),
              PillButton(
                label: addresses.isEmpty
                    ? '+ Add Delivery Address'
                    : 'Manage Saved Addresses',
                onPressed: () {
                  Navigator.pop(ctx);
                  context.push('/addresses');
                },
              ),
            ],
          ),
        ),
      ),
    );
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

  Future<void> _placeOrder(
    double subtotal,
    SavedAddress? selectedAddress,
  ) async {
    if (selectedAddress == null) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(
            content: Text('Please add your delivery address first'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      context.push('/addresses');
      return;
    }

    final items = ref.read(cartProvider);
    final resolvedAddress = selectedAddress.fullAddress;
    final order = await ref.read(ordersProvider.notifier).placeOrder(
          items: items,
          subtotal: subtotal,
          address: resolvedAddress,
          addressId: selectedAddress.id,
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
                'Order #${order.id} · ${money(order.total)}\nWe\'ll deliver it to $resolvedAddress.',
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
    final addresses = ref.watch(addressesProvider);
    final selectedAddress = ref.watch(selectedAddressProvider);
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
                _addressCard(addresses, selectedAddress),
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
                  onPressed: hasItems
                      ? () => _placeOrder(subtotal, selectedAddress)
                      : null,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _addressCard(
    List<SavedAddress> addresses,
    SavedAddress? selectedAddress,
  ) {
    final hasAddress = selectedAddress != null;
    final addressText = hasAddress
        ? selectedAddress.fullAddress
        : '+ Add your delivery address';
    final label = selectedAddress?.label;

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
              if (label != null && label.isNotEmpty) ...[
                const SizedBox(width: 8),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColors.primaryLight,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    label,
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: AppColors.primaryDark,
                    ),
                  ),
                ),
              ],
              const Spacer(),
              InkResponse(
                onTap: () => hasAddress
                    ? _selectOrEditAddress(addresses, selectedAddress)
                    : context.push('/addresses'),
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
          InkWell(
            borderRadius: BorderRadius.circular(8),
            onTap: () => hasAddress
                ? _selectOrEditAddress(addresses, selectedAddress)
                : context.push('/addresses'),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    addressText,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: hasAddress
                          ? CheckoutColors.title
                          : AppColors.primary,
                    ),
                  ),
                ),
                Icon(
                  Icons.chevron_right_rounded,
                  size: 20,
                  color: hasAddress ? CheckoutColors.muted : AppColors.primary,
                ),
              ],
            ),
          ),
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
