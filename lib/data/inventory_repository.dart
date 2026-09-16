import 'package:cafeteria_flutter/data/database_helper.dart';
import 'package:cafeteria_flutter/domain/inventory_math.dart';
import 'package:cafeteria_flutter/models/product.dart';
import 'package:cafeteria_flutter/models/entry.dart';
import 'package:cafeteria_flutter/models/close.dart';
import 'package:cafeteria_flutter/models/close_item.dart';
import 'package:sqflite/sqflite.dart';
import 'package:intl/intl.dart';

class InventoryRepository {
  InventoryRepository({DatabaseHelper? databaseHelper})
      : _dbHelper = databaseHelper ?? DatabaseHelper();

  final DatabaseHelper _dbHelper;
  final DateFormat _isoFormat = DateFormat('yyyy-MM-dd');

  String todayIso() => _isoFormat.format(DateTime.now());

  // --- Products ---
  Future<List<Product>> getAllProducts() async {
    final db = await _dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'products',
      where: 'isActive = 1',
      orderBy: 'name COLLATE NOCASE ASC',
    );
    return List.generate(maps.length, (i) => Product.fromMap(maps[i]));
  }

  Future<List<Product>> getArchivedProducts() async {
    final db = await _dbHelper.database;
    final maps = await db.query(
      'products',
      where: 'isActive = 0',
      orderBy: 'name COLLATE NOCASE ASC',
    );
    return maps.map(Product.fromMap).toList();
  }

  Future<Product?> getProductById(int id) async {
    final db = await _dbHelper.database;
    final List<Map<String, dynamic>> maps =
        await db.query('products', where: 'id = ?', whereArgs: [id], limit: 1);
    if (maps.isEmpty) return null;
    return Product.fromMap(maps.first);
  }

  Future<void> upsertProduct(Product product) async {
    final db = await _dbHelper.database;
    await db.transaction((txn) async {
      final now = DateTime.now().millisecondsSinceEpoch;
      if (product.id == null) {
        final id = await txn.insert('products', product.toMap());
        if (product.quantity > 0) {
          await _recordMovement(
            txn,
            productId: id,
            productName: product.name,
            delta: product.quantity,
            type: 'initial',
            note: 'Inventario inicial',
            timestamp: now,
          );
        }
        return;
      }

      final previousMaps = await txn.query(
        'products',
        where: 'id = ?',
        whereArgs: [product.id],
        limit: 1,
      );
      if (previousMaps.isEmpty) {
        throw StateError('El producto ya no existe.');
      }
      final previous = Product.fromMap(previousMaps.first);
      final values = product.toMap()..remove('id');
      await txn.update(
        'products',
        values,
        where: 'id = ?',
        whereArgs: [product.id],
      );

      final delta = product.quantity - previous.quantity;
      if (delta != 0) {
        await _recordMovement(
          txn,
          productId: product.id!,
          productName: product.name,
          delta: delta,
          type: 'adjustment',
          note: 'Ajuste desde la ficha del producto',
          timestamp: now,
        );
        await _updateClosureForEntryChange(
          txn,
          todayIso(),
          product.id!,
          delta,
        );
      }
    });
  }

  Future<void> deleteProduct(int id) async {
    final db = await _dbHelper.database;
    await db.update(
      'products',
      {
        'isActive': 0,
        'updatedAt': DateTime.now().millisecondsSinceEpoch,
      },
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> restoreProduct(int id) async {
    final db = await _dbHelper.database;
    await db.update(
      'products',
      {
        'isActive': 1,
        'updatedAt': DateTime.now().millisecondsSinceEpoch,
      },
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // --- Home Stats ---
  Future<double> getTotalInvestment() async {
    final db = await _dbHelper.database;
    final result = await db.rawQuery(
      'SELECT SUM(quantity * costPrice) as total '
      'FROM products WHERE isActive = 1',
    );
    return (result.first['total'] as num?)?.toDouble() ?? 0.0;
  }

  Future<int> getProductCount() async {
    final db = await _dbHelper.database;
    final result = await db.rawQuery(
      'SELECT COUNT(*) as count FROM products WHERE isActive = 1',
    );
    return Sqflite.firstIntValue(result) ?? 0;
  }

  Future<double> getAvgDailyProfit() async {
    final db = await _dbHelper.database;
    final result =
        await db.rawQuery('SELECT AVG(totalProfit) as avgProfit FROM closes');
    return (result.first['avgProfit'] as num?)?.toDouble() ?? 0.0;
  }

  // --- Entries ---
  Future<List<Entry>> getAllEntries() async {
    final db = await _dbHelper.database;
    final List<Map<String, dynamic>> maps =
        await db.query('entries', orderBy: 'timestamp DESC');
    return List.generate(maps.length, (i) => Entry.fromMap(maps[i]));
  }

  Future<void> addEntries(Map<int, int> deltaByProductId) async {
    final db = await _dbHelper.database;
    await db.transaction((txn) async {
      final now = DateTime.now().millisecondsSinceEpoch;
      final dateStr = todayIso();

      for (var entry in deltaByProductId.entries) {
        final id = entry.key;
        final delta = entry.value;
        if (delta <= 0) continue;

        final productMaps = await txn.query('products',
            where: 'id = ?', whereArgs: [id], limit: 1);
        if (productMaps.isNotEmpty) {
          final p = Product.fromMap(productMaps.first);

          await txn.insert('entries', {
            'productId': id,
            'productName': p.name,
            'quantity': delta,
            'date': dateStr,
            'timestamp': now,
          });

          await txn.rawUpdate(
              'UPDATE products SET quantity = quantity + ?, updatedAt = ? WHERE id = ?',
              [delta, now, id]);

          await _recordMovement(
            txn,
            productId: id,
            productName: p.name,
            delta: delta,
            type: 'entry',
            note: 'Entrada de mercancía',
            timestamp: now,
          );

          await _updateClosureForEntryChange(txn, dateStr, id, delta);
        }
      }
    });
  }

  Future<void> deleteEntry(Entry entry) async {
    final db = await _dbHelper.database;
    await db.transaction((txn) async {
      final now = DateTime.now().millisecondsSinceEpoch;
      final entryMaps = await txn.query(
        'entries',
        where: 'id = ?',
        whereArgs: [entry.id],
        limit: 1,
      );
      if (entryMaps.isEmpty) {
        throw StateError('La entrada ya no existe.');
      }
      final currentEntry = Entry.fromMap(entryMaps.first);
      final productMaps = await txn.query(
        'products',
        where: 'id = ?',
        whereArgs: [currentEntry.productId],
        limit: 1,
      );
      if (productMaps.isEmpty) {
        throw StateError('No se encontró el producto asociado.');
      }
      final product = Product.fromMap(productMaps.first);
      if (product.quantity < currentEntry.quantity) {
        throw StateError(
          'No se puede eliminar la entrada porque dejaría el stock negativo.',
        );
      }
      await txn.rawUpdate(
          'UPDATE products SET quantity = quantity - ?, updatedAt = ? WHERE id = ?',
          [currentEntry.quantity, now, currentEntry.productId]);

      await _recordMovement(
        txn,
        productId: currentEntry.productId,
        productName: currentEntry.productName,
        delta: -currentEntry.quantity,
        type: 'entry_reversal',
        note: 'Eliminación de una entrada',
        timestamp: now,
      );

      await _updateClosureForEntryChange(txn, currentEntry.date,
          currentEntry.productId, -currentEntry.quantity);
      await txn
          .delete('entries', where: 'id = ?', whereArgs: [currentEntry.id]);
    });
  }

  Future<void> _updateClosureForEntryChange(
      Transaction txn, String date, int productId, int deltaQty) async {
    final closeMaps = await txn.query('closes',
        where: 'date = ?', whereArgs: [date], limit: 1);
    if (closeMaps.isEmpty) return;

    final itemMaps = await txn.query('close_items',
        where: 'closeDate = ? AND productId = ?', whereArgs: [date, productId]);
    if (itemMaps.isEmpty) return;

    final targetItem = CloseItem.fromMap(itemMaps.first);
    final newInitial = targetItem.initialQty + deltaQty;
    final newFinal = targetItem.finalQty + deltaQty;
    if (newInitial < 0 || newFinal < 0) {
      throw StateError('El ajuste dejaría negativo el conteo del cierre.');
    }

    await txn.update(
      'close_items',
      {'initialQty': newInitial, 'finalQty': newFinal},
      where: 'closeDate = ? AND productId = ?',
      whereArgs: [date, productId],
    );
  }

  // --- Closes ---
  Future<List<Close>> getAllCloses() async {
    final db = await _dbHelper.database;
    final List<Map<String, dynamic>> maps =
        await db.query('closes', orderBy: 'date DESC');
    return List.generate(maps.length, (i) => Close.fromMap(maps[i]));
  }

  Future<List<CloseItem>> getCloseItems(String date) async {
    final db = await _dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query('close_items',
        where: 'closeDate = ?',
        whereArgs: [date],
        orderBy: 'productName COLLATE NOCASE ASC');
    return List.generate(maps.length, (i) => CloseItem.fromMap(maps[i]));
  }

  Future<bool> closeExists(String date) async {
    final db = await _dbHelper.database;
    final maps = await db.query('closes',
        where: 'date = ?', whereArgs: [date], limit: 1);
    return maps.isNotEmpty;
  }

  Future<bool> productUsedInCloses(int productId) async {
    final db = await _dbHelper.database;
    final maps = await db.query('close_items',
        where: 'productId = ?', whereArgs: [productId], limit: 1);
    return maps.isNotEmpty;
  }

  Future<void> generateClose(
      String date, Map<int, int> finalQtyByProductId) async {
    final db = await _dbHelper.database;
    await db.transaction((txn) async {
      final existing = await txn.query('closes',
          where: 'date = ?', whereArgs: [date], limit: 1);
      if (existing.isNotEmpty) {
        throw Exception('Ya existe un cierre para esta fecha.');
      }

      final productMaps = await txn.query('products', where: 'isActive = 1');
      final products = productMaps.map((m) => Product.fromMap(m)).toList();

      int totalSold = 0;
      double totalRevenue = 0.0;
      double totalProfit = 0.0;
      final now = DateTime.now().millisecondsSinceEpoch;

      await txn.insert('closes', {
        'date': date,
        'totalSoldUnits': 0,
        'totalRevenue': 0.0,
        'totalProfit': 0.0,
        'createdAt': now,
      });

      for (var p in products) {
        final initial = p.quantity;
        final finalQty =
            (finalQtyByProductId[p.id] ?? initial).clamp(0, 999999).toInt();
        final sold = InventoryMath.soldUnits(
          initial: initial,
          finalQuantity: finalQty,
        );

        final revenue =
            InventoryMath.revenue(sold: sold, salePrice: p.salePrice);
        final profit = InventoryMath.profit(
          sold: sold,
          salePrice: p.salePrice,
          costPrice: p.costPrice,
        );

        totalSold += sold;
        totalRevenue += revenue;
        totalProfit += profit;

        await txn.insert('close_items', {
          'closeDate': date,
          'productId': p.id,
          'productName': p.name,
          'initialQty': initial,
          'finalQty': finalQty,
          'soldUnits': sold,
          'revenue': revenue,
          'profit': profit,
          'costPrice': p.costPrice,
          'salePrice': p.salePrice,
        });

        await txn.update('products', {'quantity': finalQty, 'updatedAt': now},
            where: 'id = ?', whereArgs: [p.id]);
      }

      await txn.update(
          'closes',
          {
            'totalSoldUnits': totalSold,
            'totalRevenue': totalRevenue,
            'totalProfit': totalProfit,
          },
          where: 'date = ?',
          whereArgs: [date]);
    });
  }

  Future<void> updateClose(
      String date, Map<int, int> finalQtyByProductId) async {
    final db = await _dbHelper.database;
    await db.transaction((txn) async {
      final previousItemsMaps = await txn
          .query('close_items', where: 'closeDate = ?', whereArgs: [date]);
      final previousItems =
          previousItemsMaps.map((m) => CloseItem.fromMap(m)).toList();
      final previousProductIds =
          previousItems.map((item) => item.productId).toSet();

      final now = DateTime.now().millisecondsSinceEpoch;
      int totalSold = 0;
      double totalRevenue = 0.0;
      double totalProfit = 0.0;

      for (var old in previousItems) {
        final productMaps = await txn.query('products',
            where: 'id = ?', whereArgs: [old.productId], limit: 1);
        if (productMaps.isEmpty) continue;
        final p = Product.fromMap(productMaps.first);

        // An omitted product must keep its current quantity. Reusing the old
        // final count here would silently discard entries made after closing.
        final finalQty = (finalQtyByProductId[old.productId] ?? p.quantity)
            .clamp(0, 999999)
            .toInt();
        final sold = InventoryMath.soldUnits(
          initial: old.initialQty,
          finalQuantity: finalQty,
        );

        totalSold += sold;
        totalRevenue =
            InventoryMath.money(totalRevenue + (sold * old.salePrice));
        totalProfit = InventoryMath.money(
          totalProfit + (sold * (old.salePrice - old.costPrice)),
        );

        await txn.update(
            'close_items',
            {
              'finalQty': finalQty,
              'soldUnits': sold,
              'revenue':
                  InventoryMath.revenue(sold: sold, salePrice: old.salePrice),
              'profit': InventoryMath.profit(
                sold: sold,
                salePrice: old.salePrice,
                costPrice: old.costPrice,
              ),
            },
            where: 'closeDate = ? AND productId = ?',
            whereArgs: [date, old.productId]);

        await txn.update('products', {'quantity': finalQty, 'updatedAt': now},
            where: 'id = ?', whereArgs: [p.id]);
      }

      // Products created after the first close also belong to an updated
      // close; otherwise a count entered for them would be silently ignored.
      final activeProductMaps =
          await txn.query('products', where: 'isActive = 1');
      for (final productMap in activeProductMaps) {
        final product = Product.fromMap(productMap);
        if (previousProductIds.contains(product.id)) continue;

        final initial = product.quantity;
        final finalQty = (finalQtyByProductId[product.id] ?? initial)
            .clamp(0, 999999)
            .toInt();
        final sold = InventoryMath.soldUnits(
          initial: initial,
          finalQuantity: finalQty,
        );
        final revenue = InventoryMath.revenue(
          sold: sold,
          salePrice: product.salePrice,
        );
        final profit = InventoryMath.profit(
          sold: sold,
          salePrice: product.salePrice,
          costPrice: product.costPrice,
        );

        totalSold += sold;
        totalRevenue = InventoryMath.money(totalRevenue + revenue);
        totalProfit = InventoryMath.money(totalProfit + profit);

        await txn.insert('close_items', {
          'closeDate': date,
          'productId': product.id,
          'productName': product.name,
          'initialQty': initial,
          'finalQty': finalQty,
          'soldUnits': sold,
          'revenue': revenue,
          'profit': profit,
          'costPrice': product.costPrice,
          'salePrice': product.salePrice,
        });
        await txn.update('products', {'quantity': finalQty, 'updatedAt': now},
            where: 'id = ?', whereArgs: [product.id]);
      }

      await txn.update(
          'closes',
          {
            'totalSoldUnits': totalSold,
            'totalRevenue': totalRevenue,
            'totalProfit': totalProfit,
          },
          where: 'date = ?',
          whereArgs: [date]);
    });
  }

  Future<void> _recordMovement(
    DatabaseExecutor db, {
    required int productId,
    required String productName,
    required int delta,
    required String type,
    required int timestamp,
    String? note,
  }) async {
    await db.insert('inventory_movements', {
      'productId': productId,
      'productName': productName,
      'quantityDelta': delta,
      'type': type,
      'note': note,
      'timestamp': timestamp,
    });
  }
}
