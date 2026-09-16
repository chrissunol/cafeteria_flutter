class Product {
  final int? id;
  final String name;
  final double costPrice;
  final double salePrice;
  final int quantity;
  final int minStock;
  final int updatedAt;
  final bool isActive;

  Product({
    this.id,
    required this.name,
    required this.costPrice,
    required this.salePrice,
    required this.quantity,
    required this.minStock,
    required this.updatedAt,
    this.isActive = true,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'costPrice': costPrice,
      'salePrice': salePrice,
      'quantity': quantity,
      'minStock': minStock,
      'updatedAt': updatedAt,
      'isActive': isActive ? 1 : 0,
    };
  }

  factory Product.fromMap(Map<String, dynamic> map) {
    return Product(
      id: map['id'] as int?,
      name: map['name'] as String,
      costPrice: (map['costPrice'] as num).toDouble(),
      salePrice: (map['salePrice'] as num).toDouble(),
      quantity: (map['quantity'] as num).toInt(),
      minStock: (map['minStock'] as num).toInt(),
      updatedAt: (map['updatedAt'] as num).toInt(),
      isActive: (map['isActive'] as num?)?.toInt() != 0,
    );
  }
}
