import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../models/category.dart';
import '../../services/api_client.dart';

class CategoryVisual {
  final IconData icon;
  final Color color;

  const CategoryVisual(this.icon, this.color);

  static CategoryVisual forName(String name) {
    final lower = name.toLowerCase();
    if (lower.contains('fruit') || lower.contains('apple')) {
      return const CategoryVisual(Icons.apple_rounded, Color(0xFFE53935));
    }
    if (lower.contains('veg') || lower.contains('broccoli') || lower.contains('organic')) {
      return const CategoryVisual(Icons.eco_rounded, Color(0xFF43A047));
    }
    if (lower.contains('dairy') ||
        lower.contains('egg') ||
        lower.contains('milk') ||
        lower.contains('drink') ||
        lower.contains('beverage')) {
      return const CategoryVisual(Icons.local_drink_rounded, Color(0xFF4CAF50));
    }
    if (lower.contains('meat') ||
        lower.contains('beef') ||
        lower.contains('chicken') ||
        lower.contains('pork') ||
        lower.contains('fish')) {
      return const CategoryVisual(Icons.restaurant_rounded, Color(0xFFEF6C4D));
    }
    if (lower.contains('bake') || lower.contains('bread') || lower.contains('cake')) {
      return const CategoryVisual(Icons.bakery_dining_rounded, Color(0xFFE0A24A));
    }
    if (lower.contains('office') || lower.contains('stationery')) {
      return const CategoryVisual(Icons.chair_rounded, Color(0xFF3FB68B));
    }
    if (lower.contains('coffee') || lower.contains('tea')) {
      return const CategoryVisual(Icons.coffee_rounded, Color(0xFF795548));
    }
    if (lower.contains('baby') || lower.contains('kid')) {
      return const CategoryVisual(Icons.child_friendly_rounded, Color(0xFFEC6FA0));
    }
    if (lower.contains('house') || lower.contains('clean') || lower.contains('home')) {
      return const CategoryVisual(Icons.cleaning_services_rounded, Color(0xFF7E57C2));
    }
    return const CategoryVisual(Icons.shopping_basket_rounded, Color(0xFFEF6C4D));
  }
}

class CategoryIcon extends StatelessWidget {
  final Category category;
  final double size;

  const CategoryIcon({
    super.key,
    required this.category,
    this.size = 28,
  });

  @override
  Widget build(BuildContext context) {
    final visual = CategoryVisual.forName(category.name);
    final raw = category.iconAsset.trim();
    final fallback = Icon(visual.icon, color: visual.color, size: size);

    if (raw.isEmpty || raw.startsWith('assets/icons/')) {
      // Seeded placeholder paths like 'assets/icons/fruits.png' use our vector icon.
      return fallback;
    }

    final url = ApiClient.instance.resolveStorageUrl(raw);
    if (url.toLowerCase().endsWith('.svg')) {
      return SvgPicture.network(
        url,
        width: size,
        height: size,
        placeholderBuilder: (_) => fallback,
        errorBuilder: (_, _, _) => fallback,
      );
    }

    return CachedNetworkImage(
      imageUrl: url,
      width: size,
      height: size,
      fit: BoxFit.contain,
      placeholder: (_, _) => fallback,
      errorWidget: (_, _, _) => fallback,
    );
  }
}

