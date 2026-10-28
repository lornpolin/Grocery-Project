class Product {
  final String id;
  final String name;
  final String description;
  final String imageUrl;
  final List<String> images;
  final double price;
  final double? originalPrice;
  final String unit;
  final String categoryId;
  final int stockQuantity;
  final bool isFavorite;

  const Product({
    required this.id,
    required this.name,
    required this.description,
    required this.imageUrl,
    this.images = const [],
    required this.price,
    this.originalPrice,
    required this.unit,
    required this.categoryId,
    required this.stockQuantity,
    this.isFavorite = false,
  });

  factory Product.fromJson(Map<String, dynamic> json) {
    final rawImages = (json['images'] as List<dynamic>?)
            ?.map((e) => e.toString())
            .where((e) => e.isNotEmpty)
            .toList() ??
        const <String>[];
    final primaryImage = (json['imageUrl'] ?? json['image_url'] ?? '').toString();

    return Product(
      id: (json['id'] ?? '').toString(),
      name: (json['name'] ?? '').toString(),
      description: (json['description'] ?? '').toString(),
      imageUrl: primaryImage.isNotEmpty
          ? primaryImage
          : (rawImages.isNotEmpty ? rawImages.first : ''),
      images: rawImages.isNotEmpty
          ? rawImages
          : (primaryImage.isNotEmpty ? [primaryImage] : const []),
      price: (json['price'] as num?)?.toDouble() ?? 0.0,
      originalPrice: (json['originalPrice'] ?? json['original_price']) != null
          ? ((json['originalPrice'] ?? json['original_price']) as num).toDouble()
          : null,
      unit: (json['unit'] ?? '').toString(),
      categoryId: (json['categoryId'] ?? json['category_id'] ?? '').toString(),
      stockQuantity:
          (json['stockQuantity'] ?? json['stock_quantity'] as num?)?.toInt() ??
              0,
      isFavorite: json['isFavorite'] == true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'imageUrl': imageUrl,
      'images': images,
      'price': price,
      'originalPrice': originalPrice,
      'unit': unit,
      'categoryId': categoryId,
      'stockQuantity': stockQuantity,
      'isFavorite': isFavorite,
    };
  }

  Product copyWith({
    String? id,
    String? name,
    String? description,
    String? imageUrl,
    List<String>? images,
    double? price,
    double? originalPrice,
    String? unit,
    String? categoryId,
    int? stockQuantity,
    bool? isFavorite,
  }) {
    return Product(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      imageUrl: imageUrl ?? this.imageUrl,
      images: images ?? this.images,
      price: price ?? this.price,
      originalPrice: originalPrice ?? this.originalPrice,
      unit: unit ?? this.unit,
      categoryId: categoryId ?? this.categoryId,
      stockQuantity: stockQuantity ?? this.stockQuantity,
      isFavorite: isFavorite ?? this.isFavorite,
    );
  }
}
