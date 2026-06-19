class Product {
  final int? id;
  final String name;
  final double costPrice;
  final double salePrice;
  final int quantity;
  final int minStock;
  final int updatedAt;

  Product({
    this.id,
    required this.name,
    required this.costPrice,
    required this.salePrice,
    required this.quantity,
    required this.minStock,
    required this.updatedAt,
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
    };
  }

  factory Product.fromMap(Map<String, dynamic> map) {
    return Product(
      id: map['id'],
      name: map['name'],
      costPrice: map['costPrice'],
      salePrice: map['salePrice'],
      quantity: map['quantity'],
      minStock: map['minStock'],
      updatedAt: map['updatedAt'],
    );
  }
}
