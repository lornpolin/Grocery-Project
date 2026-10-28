class SavedAddress {
  final String id;
  final String label;
  final String? recipientName;
  final String? phone;
  final String address;
  final String? city;
  final bool isDefault;

  const SavedAddress({
    required this.id,
    required this.label,
    this.recipientName,
    this.phone,
    required this.address,
    this.city,
    this.isDefault = false,
  });

  String get fullAddress {
    final c = city?.trim() ?? '';
    if (c.isEmpty || address.toLowerCase().contains(c.toLowerCase())) {
      return address;
    }
    return '$address, $c';
  }

  /// Short location label for the top header (e.g. "Phnom Penh").
  String get headerLocation {
    final c = city?.trim() ?? '';
    if (c.isNotEmpty) return c;
    if (address.contains(',')) {
      final lastPart = address.split(',').last.trim();
      if (lastPart.isNotEmpty) return lastPart;
    }
    return address.trim().isNotEmpty ? address.trim() : 'Phnom Penh';
  }

  SavedAddress copyWith({
    String? id,
    String? label,
    String? recipientName,
    String? phone,
    String? address,
    String? city,
    bool? isDefault,
  }) {
    return SavedAddress(
      id: id ?? this.id,
      label: label ?? this.label,
      recipientName: recipientName ?? this.recipientName,
      phone: phone ?? this.phone,
      address: address ?? this.address,
      city: city ?? this.city,
      isDefault: isDefault ?? this.isDefault,
    );
  }

  factory SavedAddress.fromJson(Map<String, dynamic> json) {
    return SavedAddress(
      id: (json['id'] ?? '').toString(),
      label: (json['label'] ?? 'Home').toString(),
      recipientName: json['recipientName']?.toString() ??
          json['recipient_name']?.toString(),
      phone: json['phone']?.toString(),
      address: (json['address'] ?? '').toString(),
      city: json['city']?.toString(),
      isDefault: json['isDefault'] == true || json['is_default'] == true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'label': label,
      'recipientName': recipientName,
      'phone': phone,
      'address': address,
      'city': city,
      'isDefault': isDefault,
    };
  }
}

