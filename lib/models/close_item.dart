class CloseItem {
  final String closeDate;
  final int productId;
  final String productName;
  final int initialQty;
  final int finalQty;
  final int soldUnits;
  final double revenue;
  final double profit;
  final double costPrice;
  final double salePrice;

  CloseItem({
    required this.closeDate,
    required this.productId,
    required this.productName,
    required this.initialQty,
    required this.finalQty,
    required this.soldUnits,
    required this.revenue,
    required this.profit,
    required this.costPrice,
    required this.salePrice,
  });

  Map<String, dynamic> toMap() {
    return {
      'closeDate': closeDate,
      'productId': productId,
      'productName': productName,
      'initialQty': initialQty,
      'finalQty': finalQty,
      'soldUnits': soldUnits,
      'revenue': revenue,
      'profit': profit,
      'costPrice': costPrice,
      'salePrice': salePrice,
    };
  }

  factory CloseItem.fromMap(Map<String, dynamic> map) {
    return CloseItem(
      closeDate: map['closeDate'],
      productId: (map['productId'] as num).toInt(),
      productName: map['productName'] as String,
      initialQty: (map['initialQty'] as num).toInt(),
      finalQty: (map['finalQty'] as num).toInt(),
      soldUnits: (map['soldUnits'] as num).toInt(),
      revenue: (map['revenue'] as num).toDouble(),
      profit: (map['profit'] as num).toDouble(),
      costPrice: (map['costPrice'] as num?)?.toDouble() ?? 0,
      salePrice: (map['salePrice'] as num?)?.toDouble() ?? 0,
    );
  }
}
