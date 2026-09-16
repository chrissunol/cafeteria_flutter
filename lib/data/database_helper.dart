import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseHelper {
  static const int schemaVersion = 2;
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  factory DatabaseHelper() => _instance;
  DatabaseHelper._internal()
      : _databaseFactory = null,
        _databasePath = null;

  DatabaseHelper.forTesting({
    required DatabaseFactory databaseFactory,
    required String databasePath,
  })  : _databaseFactory = databaseFactory,
        _databasePath = databasePath;

  final DatabaseFactory? _databaseFactory;
  final String? _databasePath;
  Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final path = _databasePath ??
        join(await (_databaseFactory ?? databaseFactory).getDatabasesPath(),
            'cafeteria.db');
    return (_databaseFactory ?? databaseFactory).openDatabase(
      path,
      options: OpenDatabaseOptions(
        version: schemaVersion,
        onConfigure: (db) => db.execute('PRAGMA foreign_keys = ON'),
        onCreate: _onCreate,
        onUpgrade: _onUpgrade,
      ),
    );
  }

  Future<void> close() async {
    final current = _database;
    _database = null;
    if (current != null) await current.close();
  }

  Future _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE products (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        costPrice REAL NOT NULL CHECK(costPrice >= 0),
        salePrice REAL NOT NULL CHECK(salePrice >= 0),
        quantity INTEGER NOT NULL CHECK(quantity >= 0),
        minStock INTEGER NOT NULL CHECK(minStock >= 0),
        updatedAt INTEGER NOT NULL,
        isActive INTEGER NOT NULL DEFAULT 1 CHECK(isActive IN (0, 1))
      )
    ''');

    await db.execute('''
      CREATE TABLE entries (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        productId INTEGER NOT NULL,
        productName TEXT NOT NULL,
        quantity INTEGER NOT NULL CHECK(quantity > 0),
        date TEXT NOT NULL,
        timestamp INTEGER NOT NULL,
        FOREIGN KEY(productId) REFERENCES products(id)
      )
    ''');

    await db.execute('''
      CREATE TABLE closes (
        date TEXT PRIMARY KEY,
        totalSoldUnits INTEGER NOT NULL,
        totalRevenue REAL NOT NULL,
        totalProfit REAL NOT NULL,
        createdAt INTEGER NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE close_items (
        closeDate TEXT NOT NULL,
        productId INTEGER NOT NULL,
        productName TEXT NOT NULL,
        initialQty INTEGER NOT NULL,
        finalQty INTEGER NOT NULL,
        soldUnits INTEGER NOT NULL,
        revenue REAL NOT NULL,
        profit REAL NOT NULL,
        costPrice REAL NOT NULL,
        salePrice REAL NOT NULL,
        PRIMARY KEY (closeDate, productId),
        FOREIGN KEY(closeDate) REFERENCES closes(date) ON DELETE CASCADE,
        FOREIGN KEY(productId) REFERENCES products(id)
      )
    ''');

    await _createSupportingSchema(db);
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute(
        'ALTER TABLE products ADD COLUMN isActive INTEGER NOT NULL DEFAULT 1',
      );
      await db.execute(
        'ALTER TABLE close_items ADD COLUMN costPrice REAL NOT NULL DEFAULT 0',
      );
      await db.execute(
        'ALTER TABLE close_items ADD COLUMN salePrice REAL NOT NULL DEFAULT 0',
      );
      await db.execute('''
        UPDATE close_items
        SET salePrice = CASE
          WHEN soldUnits > 0 THEN revenue / soldUnits
          ELSE COALESCE(
            (SELECT salePrice FROM products WHERE products.id = close_items.productId),
            0
          )
        END
      ''');
      await db.execute('''
        UPDATE close_items
        SET costPrice = CASE
          WHEN soldUnits > 0 THEN salePrice - (profit / soldUnits)
          ELSE COALESCE(
            (SELECT costPrice FROM products WHERE products.id = close_items.productId),
            0
          )
        END
      ''');
      await _createSupportingSchema(db);
    }
  }

  Future<void> _createSupportingSchema(DatabaseExecutor db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS inventory_movements (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        productId INTEGER NOT NULL,
        productName TEXT NOT NULL,
        quantityDelta INTEGER NOT NULL,
        type TEXT NOT NULL,
        note TEXT,
        timestamp INTEGER NOT NULL,
        FOREIGN KEY(productId) REFERENCES products(id)
      )
    ''');
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_products_active_name ON products(isActive, name COLLATE NOCASE)',
    );
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_entries_product_date ON entries(productId, date)',
    );
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_movements_product_time ON inventory_movements(productId, timestamp)',
    );
  }
}
