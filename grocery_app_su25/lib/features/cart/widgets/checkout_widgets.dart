import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';

/// Shared colors for the cart → checkout flow.
class CheckoutColors {
  static const Color pageBg = Color(0xFFF5F7FA);
  static const Color title = Color(0xFF0F172A);
  static const Color label = Color(0xFF334155);
  static const Color muted = Color(0xFF64748B);
  static const Color hint = Color(0xFF94A3B8);
  static const Color line = Color(0xFFE2E8F0);
}

String money(double v) => '\$${v.toStringAsFixed(2)}';

/// Centered title with a circular outlined back button on the left.
class CheckoutAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final VoidCallback onBack;
  const CheckoutAppBar({super.key, required this.title, required this.onBack});

  @override
  Size get preferredSize => const Size.fromHeight(60);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: CheckoutColors.pageBg,
      surfaceTintColor: Colors.transparent,
      toolbarHeight: 60,
      leadingWidth: 64,
      leading: Center(
        child: InkResponse(
          onTap: onBack,
          radius: 22,
          child: Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.primary, width: 1.8),
            ),
            child: const Icon(Icons.arrow_back_rounded,
                size: 18, color: AppColors.primary),
          ),
        ),
      ),
      title: Text(title,
          style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: CheckoutColors.title)),
    );
  }
}

/// 3-step progress: Menu → Basket → Checkout. [current] is 1-based.
class CheckoutStepper extends StatelessWidget {
  final int current;
  const CheckoutStepper({super.key, required this.current});

  static const _labels = ['Menu', 'Basket', 'Checkout'];

  @override
  Widget build(BuildContext context) {
    Widget dot(int step) {
      final active = step <= current;
      return Container(
        width: 22,
        height: 22,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: active ? AppColors.primary : Colors.white,
          border: Border.all(
              color: active ? AppColors.primary : CheckoutColors.line,
              width: 1.5),
          boxShadow: active
              ? [
                  BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.3),
                      blurRadius: 6,
                      offset: const Offset(0, 2)),
                ]
              : null,
        ),
        child: Text('$step',
            style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: active ? Colors.white : CheckoutColors.hint)),
      );
    }

    Widget bar(int afterStep) => Expanded(
          child: Container(
            height: 2,
            color: afterStep < current ? AppColors.primary : CheckoutColors.line,
          ),
        );

    Widget label(int step, TextAlign align) => Expanded(
          child: Text(_labels[step - 1],
              textAlign: align,
              style: TextStyle(
                  fontSize: 11,
                  fontWeight: step == current ? FontWeight.w700 : FontWeight.w500,
                  color: step <= current
                      ? CheckoutColors.label
                      : CheckoutColors.hint)),
        );

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
      child: Column(
        children: [
          Row(children: [dot(1), bar(1), dot(2), bar(2), dot(3)]),
          const SizedBox(height: 6),
          Row(children: [
            label(1, TextAlign.left),
            label(2, TextAlign.center),
            label(3, TextAlign.right),
          ]),
        ],
      ),
    );
  }
}

/// One line of the price breakdown.
class SummaryRow extends StatelessWidget {
  final String label;
  final double amount;
  final bool emphasized;
  const SummaryRow(
      {super.key,
      required this.label,
      required this.amount,
      this.emphasized = false});

  @override
  Widget build(BuildContext context) {
    final style = emphasized
        ? const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: CheckoutColors.title)
        : const TextStyle(fontSize: 14, color: CheckoutColors.muted);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [Text(label, style: style), Text(money(amount), style: style)],
      ),
    );
  }
}

/// "Total (Incl. delivery charge)" row plus the Apply Voucher link.
class TotalWithVoucher extends StatelessWidget {
  final double total;
  const TotalWithVoucher({super.key, required this.total});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            const Text('Total',
                style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: CheckoutColors.title)),
            const SizedBox(width: 4),
            const Padding(
              padding: EdgeInsets.only(bottom: 1),
              child: Text('(Incl. delivery charge)',
                  style: TextStyle(fontSize: 12, color: CheckoutColors.muted)),
            ),
            const Spacer(),
            Text(money(total),
                style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: AppColors.primary)),
          ],
        ),
        const SizedBox(height: 10),
        InkWell(
          borderRadius: BorderRadius.circular(6),
          onTap: () => ScaffoldMessenger.of(context)
            ..hideCurrentSnackBar()
            ..showSnackBar(const SnackBar(
                content: Text('Vouchers are coming soon'))),
          child: const Padding(
            padding: EdgeInsets.symmetric(vertical: 4),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.confirmation_number_outlined,
                    size: 16, color: AppColors.primary),
                SizedBox(width: 8),
                Text('APPLY VOUCHER',
                    style: TextStyle(
                        fontSize: 12,
                        letterSpacing: 0.6,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primary)),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

/// Full-width rounded primary button with a soft glow.
class PillButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  const PillButton({super.key, required this.label, this.onPressed});

  @override
  Widget build(BuildContext context) {
    final enabled = onPressed != null;
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        boxShadow: enabled
            ? [
                BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.35),
                    blurRadius: 14,
                    offset: const Offset(0, 6)),
              ]
            : null,
      ),
      child: SizedBox(
        width: double.infinity,
        height: 54,
        child: ElevatedButton(
          onPressed: onPressed,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            disabledBackgroundColor: AppColors.primarySoft,
            foregroundColor: Colors.white,
            disabledForegroundColor: Colors.white,
            elevation: 0,
            padding: EdgeInsets.zero,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(28)),
          ),
          child: Text(label,
              style:
                  const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
        ),
      ),
    );
  }
}

/// White rounded card used for checkout sections.
class CheckoutCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  const CheckoutCard(
      {super.key,
      required this.child,
      this.padding = const EdgeInsets.all(16)});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: padding,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 10,
              offset: const Offset(0, 2)),
        ],
      ),
      child: child,
    );
  }
}
