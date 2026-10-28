import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';

class BrandColors {
  static const Color primary = AppColors.primary;
  static const Color primaryDark = AppColors.primaryDark;
  static const Color primarySoft = AppColors.primarySoft;
  static const Color navy = Color(0xFF1E293B);
  static const Color slate = Color(0xFF64748B);
  static const Color bg = AppColors.primaryBg;
  static const Color wave = AppColors.primaryTint;
}

/// Soft mint background with decorative plus patterns and a wave footer.
class BrandBackground extends StatelessWidget {
  final Widget child;
  const BrandBackground({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: BrandColors.bg,
      child: Stack(
        children: [
          Positioned.fill(child: CustomPaint(painter: _PlusPatternPainter())),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            height: 130,
            child: CustomPaint(painter: _WavePainter()),
          ),
          Positioned.fill(child: child),
        ],
      ),
    );
  }
}

class _PlusPatternPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = BrandColors.wave.withValues(alpha: 0.45);
    void plus(double cx, double cy, double s) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(center: Offset(cx, cy), width: s, height: s / 3),
          const Radius.circular(4),
        ),
        paint,
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(center: Offset(cx, cy), width: s / 3, height: s),
          const Radius.circular(4),
        ),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter old) => false;
}

class _WavePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final path = Path()
      ..moveTo(0, size.height * 0.45)
      ..cubicTo(
        size.width * 0.25,
        size.height * 0.05,
        size.width * 0.45,
        size.height * 0.1,
        size.width * 0.62,
        size.height * 0.45,
      )
      ..cubicTo(
        size.width * 0.8,
        size.height * 0.75,
        size.width * 0.92,
        size.height * 0.5,
        size.width,
        size.height * 0.35,
      )
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();
    canvas.drawPath(path, Paint()..color = BrandColors.wave);
  }

  @override
  bool shouldRepaint(covariant CustomPainter old) => false;
}

/// Rounded white tile with basket icon and leaf badge.
class BrandLogo extends StatelessWidget {
  final double size;
  const BrandLogo({super.key, this.size = 148});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(size * 0.3),
        boxShadow: [
          BoxShadow(
            color: BrandColors.primary.withValues(alpha: 0.18),
            blurRadius: 36,
            offset: const Offset(0, 16),
          ),
        ],
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Icon(
            Icons.shopping_basket_rounded,
            size: size * 0.5,
            color: BrandColors.primary,
          ),
          Positioned(
            top: size * 0.22,
            right: size * 0.2,
            child: Container(
              width: size * 0.3,
              height: size * 0.3,
              decoration: BoxDecoration(
                color: BrandColors.primaryDark,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2),
              ),
              child: Icon(
                Icons.eco_rounded,
                size: size * 0.18,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class BrandTitle extends StatelessWidget {
  const BrandTitle({super.key});

  @override
  Widget build(BuildContext context) {
    return RichText(
      text: const TextSpan(
        style: TextStyle(
          fontFamily: 'Inter',
          fontSize: 44,
          fontWeight: FontWeight.w800,
          letterSpacing: -1.5,
        ),
        children: [
          TextSpan(
            text: 'Fresh ',
            style: TextStyle(color: BrandColors.navy),
          ),
          TextSpan(
            text: 'Cart',
            style: TextStyle(color: BrandColors.primary),
          ),
        ],
      ),
    );
  }
}

class DotsIndicator extends StatelessWidget {
  final int count;
  final int index;
  const DotsIndicator({super.key, required this.count, required this.index});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(count, (i) {
        final active = i == index;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
          margin: const EdgeInsets.symmetric(horizontal: 4),
          width: active ? 22 : 10,
          height: 10,
          decoration: BoxDecoration(
            color: active
                ? BrandColors.primary
                : BrandColors.primarySoft.withValues(alpha: 0.6),
            borderRadius: BorderRadius.circular(5),
          ),
        );
      }),
    );
  }
}
