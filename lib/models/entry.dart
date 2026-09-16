class Entry {
  final int? id;
  final int productId;
  final String productName;
  final int quantity;
  final String date;
  final int timestamp;

  Entry({
    this.id,
    required this.productId,
    required this.productName,
    required this.quantity,
    required this.date,
    required this.timestamp,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'productId': productId,
      'productName': productName,
      'quantity': quantity,
      'date': date,
      'timestamp': timestamp,
    };
  }

  factory Entry.fromMap(Map<String, dynamic> map) {
    return Entry(
      id: map['id'] as int?,
      productId: (map['productId'] as num).toInt(),
      productName: map['productName'] as String,
      quantity: (map['quantity'] as num).toInt(),
      date: map['date'] as String,
      timestamp: (map['timestamp'] as num).toInt(),
    );
  }
}
