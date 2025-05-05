class Property {
  final String id;
  final String userId;
  final String address;
  final String propertyType;
  final int? bedrooms;
  final int? bathrooms;
  final double? squareFeet;
  final double? purchasePrice;
  final double? currentValue;
  final DateTime createdAt;
  final bool isAvailable;

  Property({
    required this.id,
    required this.userId,
    required this.address,
    required this.propertyType,
    this.bedrooms,
    this.bathrooms,
    this.squareFeet,
    this.purchasePrice,
    this.currentValue,
    required this.createdAt,
    this.isAvailable = true,
  });

  factory Property.fromJson(Map<String, dynamic> json) {
    return Property(
      id: json['id'],
      userId: json['user_id'],
      address: json['address'],
      propertyType: json['property_type'],
      bedrooms: json['bedrooms'],
      bathrooms: json['bathrooms'],
      squareFeet: json['square_feet']?.toDouble(),
      purchasePrice: json['purchase_price']?.toDouble(),
      currentValue: json['current_value']?.toDouble(),
      createdAt: DateTime.parse(json['created_at']),
      isAvailable: json['is_available'] ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'user_id': userId,
      'address': address,
      'property_type': propertyType,
      'bedrooms': bedrooms,
      'bathrooms': bathrooms,
      'square_feet': squareFeet,
      'purchase_price': purchasePrice,
      'current_value': currentValue,
      'is_available': isAvailable,
    };
  }
}