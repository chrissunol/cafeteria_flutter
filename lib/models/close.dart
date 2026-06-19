class Close {
  final String date;
  final int totalSoldUnits;
  final double totalRevenue;
  final double totalProfit;
  final int createdAt;

  Close({
    required this.date,
    required this.totalSoldUnits,
    required this.totalRevenue,
    required this.totalProfit,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'date': date,
      'totalSoldUnits': totalSoldUnits,
      'totalRevenue': totalRevenue,
      'totalProfit': totalProfit,
      'createdAt': createdAt,
    };
  }

  factory Close.fromMap(Map<String, dynamic> map) {
    return Close(
      date: map['date'],
      totalSoldUnits: map['totalSoldUnits'],
      totalRevenue: map['totalRevenue'],
      totalProfit: map['totalProfit'],
      createdAt: map['createdAt'],
    );
  }
}
