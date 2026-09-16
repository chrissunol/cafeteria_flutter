import 'dart:convert';
import 'dart:typed_data';

import 'package:cafeteria_flutter/data/database_helper.dart';
import 'package:cafeteria_flutter/data/backup_service.dart';
import 'package:cafeteria_flutter/data/inventory_repository.dart';
import 'package:cafeteria_flutter/models/product.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:test/test.dart';

void main() {
  late DatabaseHelper databaseHelper;
  late InventoryRepository repository;

  setUpAll(sqfliteFfiInit);

  setUp(() {
    databaseHelper = DatabaseHelper.forTesting(
      databaseFactory: databaseFactoryFfi,
      databasePath: inMemoryDatabasePath,
    );
    repository = InventoryRepository(databaseHelper: databaseHelper);
  });

  tearDown(() => databaseHelper.close());

  Future<Product> createProduct({
    String name = 'Café',
    int quantity = 10,
    double cost = 2,
    double sale = 5,
  }) async {
    await repository.upsertProduct(
      Product(
        name: name,
        costPrice: cost,
        salePrice: sale,
        quantity: quantity,
        minStock: 3,
        updatedAt: DateTime.now().millisecondsSinceEpoch,
      ),
    );
    return (await repository.getAllProducts())
        .singleWhere((product) => product.name == name);
  }

  test('updating a close preserves uncounted current inventory', () async {
    final product = await createProduct();
    final today = repository.todayIso();

    await repository.generateClose(today, {product.id!: 7});
    await repository.addEntries({product.id!: 5});

    final afterEntry = await repository.getProductById(product.id!);
    final afterEntryItem = (await repository.getCloseItems(today)).single;
    expect(afterEntry?.quantity, 12);
    expect(afterEntryItem.initialQty, 15);
    expect(afterEntryItem.finalQty, 12);
    expect(afterEntryItem.soldUnits, 3);

    await repository.updateClose(today, const {});

    final updated = await repository.getProductById(product.id!);
    final close = (await repository.getAllCloses()).single;
    expect(updated?.quantity, 12);
    expect(close.totalSoldUnits, 3);
    expect(close.totalRevenue, 15);
  });

  test('an entry after closing does not create fictitious sales', () async {
    final product = await createProduct();
    final today = repository.todayIso();
    await repository.generateClose(today, {product.id!: 7});

    await repository.addEntries({product.id!: 5});

    final item = (await repository.getCloseItems(today)).single;
    final close = (await repository.getAllCloses()).single;
    expect(item.initialQty, 15);
    expect(item.finalQty, 12);
    expect(item.soldUnits, 3);
    expect(close.totalSoldUnits, 3);
    expect(close.totalRevenue, 15);
  });

  test('a stock adjustment after closing does not change sales', () async {
    final product = await createProduct();
    final today = repository.todayIso();
    await repository.generateClose(today, {product.id!: 7});

    await repository.upsertProduct(
      Product(
        id: product.id,
        name: product.name,
        costPrice: product.costPrice,
        salePrice: product.salePrice,
        quantity: 9,
        minStock: product.minStock,
        updatedAt: DateTime.now().millisecondsSinceEpoch,
      ),
    );

    final item = (await repository.getCloseItems(today)).single;
    expect(item.initialQty, 12);
    expect(item.finalQty, 9);
    expect(item.soldUnits, 3);
    expect((await repository.getAllCloses()).single.totalRevenue, 15);
  });

  test('a new product is included when updating an existing close', () async {
    final coffee = await createProduct();
    final today = repository.todayIso();
    await repository.generateClose(today, {coffee.id!: 7});
    final tea = await createProduct(name: 'Té', quantity: 8);

    await repository.updateClose(today, {tea.id!: 6});

    final items = await repository.getCloseItems(today);
    final close = (await repository.getAllCloses()).single;
    expect(items, hasLength(2));
    expect(items.singleWhere((item) => item.productId == tea.id).soldUnits, 2);
    expect((await repository.getProductById(tea.id!))?.quantity, 6);
    expect(close.totalSoldUnits, 5);
    expect(close.totalRevenue, 25);
  });

  test('same-day entries remain separate and cannot be deleted twice',
      () async {
    final product = await createProduct();
    await repository.addEntries({product.id!: 2});
    await repository.addEntries({product.id!: 3});

    final entries = await repository.getAllEntries();
    expect(entries.map((entry) => entry.quantity), containsAll([2, 3]));
    expect(entries, hasLength(2));

    await repository.deleteEntry(entries.first);
    await expectLater(
      repository.deleteEntry(entries.first),
      throwsA(isA<StateError>()),
    );
    expect((await repository.getProductById(product.id!))?.quantity,
        15 - entries.first.quantity);
  });

  test('a close keeps the price snapshot when product prices change', () async {
    final product = await createProduct();
    final today = repository.todayIso();
    await repository.generateClose(today, {product.id!: 7});

    await repository.upsertProduct(
      Product(
        id: product.id,
        name: product.name,
        costPrice: 10,
        salePrice: 20,
        quantity: 7,
        minStock: product.minStock,
        updatedAt: DateTime.now().millisecondsSinceEpoch,
      ),
    );
    await repository.updateClose(today, {product.id!: 6});

    final close = (await repository.getAllCloses()).single;
    expect(close.totalSoldUnits, 4);
    expect(close.totalRevenue, 20);
    expect(close.totalProfit, 12);
  });

  test('archiving a product preserves its close history', () async {
    final product = await createProduct();
    final today = repository.todayIso();
    await repository.generateClose(today, {product.id!: 8});

    await repository.deleteProduct(product.id!);

    expect(await repository.getAllProducts(), isEmpty);
    expect(await repository.getArchivedProducts(), hasLength(1));
    expect(await repository.getProductCount(), 0);
    expect(await repository.getTotalInvestment(), 0);
    expect(await repository.getCloseItems(today), hasLength(1));
    expect((await repository.getProductById(product.id!))?.isActive, isFalse);
  });

  test('backup restores products and history atomically', () async {
    final product = await createProduct();
    final today = repository.todayIso();
    await repository.generateClose(today, {product.id!: 8});
    final backup =
        await BackupService(databaseHelper: databaseHelper).createBackup();

    await repository.deleteProduct(product.id!);
    await BackupService(databaseHelper: databaseHelper).restoreBackup(backup);

    expect(await repository.getAllProducts(), hasLength(1));
    expect(await repository.getCloseItems(today), hasLength(1));
    expect((await repository.getAllCloses()).single.totalSoldUnits, 2);
  });

  test('a failed restore leaves the current database untouched', () async {
    await createProduct();
    final service = BackupService(databaseHelper: databaseHelper);
    final payload = jsonDecode(utf8.decode(await service.createBackup()))
        as Map<String, dynamic>;
    payload['products'] = <Object?>[];

    await expectLater(
      service.restoreBackup(
        Uint8List.fromList(utf8.encode(jsonEncode(payload))),
      ),
      throwsA(anything),
    );

    expect(await repository.getAllProducts(), hasLength(1));
  });

  test('an entry cannot be removed if inventory would become negative',
      () async {
    final product = await createProduct();
    await repository.addEntries({product.id!: 5});
    final entry = (await repository.getAllEntries()).single;
    await repository.generateClose(repository.todayIso(), {product.id!: 2});

    await expectLater(
      repository.deleteEntry(entry),
      throwsA(isA<StateError>()),
    );
    expect((await repository.getProductById(product.id!))?.quantity, 2);
  });
}
