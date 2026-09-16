import 'package:cafeteria_flutter/domain/inventory_math.dart';
import 'package:test/test.dart';

void main() {
  group('InventoryMath', () {
    test('calcula unidades vendidas sin permitir valores negativos', () {
      expect(
        InventoryMath.soldUnits(initial: 10, finalQuantity: 4),
        6,
      );
      expect(
        InventoryMath.soldUnits(initial: 4, finalQuantity: 10),
        0,
      );
    });

    test('redondea ingresos y ganancias a centavos', () {
      expect(InventoryMath.money(10.005), 10.01);
      expect(
        InventoryMath.revenue(sold: 3, salePrice: 2.335),
        7.01,
      );
      expect(
        InventoryMath.profit(sold: 3, salePrice: 2.335, costPrice: 1.111),
        3.67,
      );
    });
  });
}
