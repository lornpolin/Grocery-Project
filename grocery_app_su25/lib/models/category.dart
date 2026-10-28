class Category {
  final String id;
  final String name;
  final String iconAsset;

  const Category({
    required this.id,
    required this.name,
    required this.iconAsset,
  });

  factory Category.fromJson(Map<String, dynamic> json) {
    return Category(
      id: (json['id'] ?? '').toString(),
      name: (json['name'] ?? '').toString(),
      iconAsset: (json['iconAsset'] ?? json['icon_asset'] ?? '').toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'iconAsset': iconAsset,
    };
  }
}
