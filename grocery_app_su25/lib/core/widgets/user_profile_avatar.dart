import 'dart:typed_data';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import '../../services/api_client.dart';
import '../constants/app_colors.dart';

/// Displays the user's circular profile image when set (either local bytes
/// preview or remote URL), or a clean default profile avatar silhouette when
/// the user does not have a profile photo yet.
class UserProfileAvatar extends StatelessWidget {
  final String? avatarUrl;
  final Uint8List? avatarBytes;
  final double size;
  final double borderWidth;
  final Color borderColor;

  const UserProfileAvatar({
    super.key,
    this.avatarUrl,
    this.avatarBytes,
    this.size = 64,
    this.borderWidth = 1.8,
    this.borderColor = AppColors.primary,
  });

  @override
  Widget build(BuildContext context) {
    final trimmedUrl = avatarUrl?.trim() ?? '';
    final resolvedUrl = trimmedUrl.isNotEmpty
        ? ApiClient.instance.resolveStorageUrl(trimmedUrl)
        : '';

    Widget inner;
    if (avatarBytes != null && avatarBytes!.isNotEmpty) {
      inner = Image.memory(
        avatarBytes!,
        fit: BoxFit.cover,
        width: size,
        height: size,
        errorBuilder: (_, _, _) => _DefaultProfileAvatar(size: size),
      );
    } else if (resolvedUrl.isNotEmpty) {
      inner = CachedNetworkImage(
        imageUrl: resolvedUrl,
        fit: BoxFit.cover,
        width: size,
        height: size,
        placeholder: (_, _) => _DefaultProfileAvatar(size: size),
        errorWidget: (_, _, _) => _DefaultProfileAvatar(size: size),
      );
    } else {
      inner = _DefaultProfileAvatar(size: size);
    }

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: const Color(0xFFEAF3FC),
        border: Border.all(color: borderColor, width: borderWidth),
      ),
      child: ClipOval(child: inner),
    );
  }
}

class _DefaultProfileAvatar extends StatelessWidget {
  final double size;

  const _DefaultProfileAvatar({required this.size});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size.square(size),
      painter: const _AvatarSilhouettePainter(),
    );
  }
}

class _AvatarSilhouettePainter extends CustomPainter {
  const _AvatarSilhouettePainter();

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final bgPaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Color(0xFFEAF3FC),
          Color(0xFFD7E8FA),
        ],
      ).createShader(rect);
    canvas.drawRect(rect, bgPaint);

    final fgPaint = Paint()
      ..color = AppColors.primary
      ..style = PaintingStyle.fill;

    // Head circle
    final headCenter = Offset(size.width * 0.5, size.height * 0.38);
    final headRadius = size.width * 0.19;
    canvas.drawCircle(headCenter, headRadius, fgPaint);

    // Smooth rounded shoulders at the bottom of the circular frame
    final shoulderRect = Rect.fromCenter(
      center: Offset(size.width * 0.5, size.height * 0.93),
      width: size.width * 0.74,
      height: size.height * 0.56,
    );
    canvas.drawOval(shoulderRect, fgPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

