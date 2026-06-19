class CloseItem {
  final String closeDate;
  final int productId;
  final String productName;
  final int initialQty;
  final int finalQty;
  final int soldUnits;
  final double revenue;
  final double profit;

  CloseItem({
    required this.closeDate,
    required this.productId,
    required this.productName,
    required this.initialQty,
    required this.finalQty,
    required this.soldUnits,
    required this.revenue,
    required this.profit,
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
    };
  }

  factory CloseItem.fromMap(Map<String, dynamic> map) {
    return CloseItem(
      closeDate: map['closeDate'],
      productId: map['productId'],
      productName: map['productName'],
      initialQty: map['initialQty'],
      finalQty: map['finalQty'],
      soldUnits: map['soldUnits'],
      revenue: map['revenue'],
      profit: map['profit'],
    );
  }
}
