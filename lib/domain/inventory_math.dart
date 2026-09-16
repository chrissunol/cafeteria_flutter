class InventoryMath {
  const InventoryMath._();

  static double money(num value) =>
      (value.toDouble() * 100).roundToDouble() / 100;

  static int soldUnits({required int initial, required int finalQuantity}) =>
      (initial - finalQuantity).clamp(0, 999999).toInt();

  static double revenue({required int sold, required double salePrice}) =>
      money(sold * salePrice);

  static double profit({
    required int sold,
    required double salePrice,
    required double costPrice,
  }) =>
      money(sold * (salePrice - costPrice));
}
