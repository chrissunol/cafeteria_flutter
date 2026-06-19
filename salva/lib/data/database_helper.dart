import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  factory DatabaseHelper() => _instance;
  DatabaseHelper._internal();

  static Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    String path = join(await getDatabasesPath(), 'cafeteria.db');
    return await openDatabase(
      path,
      version: 1,
      onCreate: _onCreate,
    );
  }

  Future _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE products (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT,
        costPrice REAL,
        salePrice REAL,
        quantity INTEGER,
        minStock INTEGER,
        updatedAt INTEGER
      )
    ''');

    await db.execute('''
      CREATE TABLE entries (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        productId INTEGER,
        productName TEXT,
        quantity INTEGER,
        date TEXT,
        timestamp INTEGER
      )
    ''');

    await db.execute('''
      CREATE TABLE closes (
        date TEXT PRIMARY KEY,
        totalSoldUnits INTEGER,
        totalRevenue REAL,
        totalProfit REAL,
        createdAt INTEGER
      )
    ''');

    await db.execute('''
      CREATE TABLE close_items (
        closeDate TEXT,
        productId INTEGER,
        productName TEXT,
        initialQty INTEGER,
        finalQty INTEGER,
        soldUnits INTEGER,
        revenue REAL,
        profit REAL,
        PRIMARY KEY (closeDate, productId)
      )
    ''');
  }
}
