import 'dart:convert';
import 'dart:typed_data';

import 'package:cafeteria_flutter/data/database_helper.dart';

class BackupService {
  BackupService({DatabaseHelper? databaseHelper})
      : _databaseHelper = databaseHelper ?? DatabaseHelper();

  static const int formatVersion = 1;
  final DatabaseHelper _databaseHelper;

  Future<Uint8List> createBackup() async {
    final db = await _databaseHelper.database;
    final payload = <String, Object?>{
      'format': 'flowstock-backup',
      'formatVersion': formatVersion,
      'schemaVersion': DatabaseHelper.schemaVersion,
      'createdAt': DateTime.now().toUtc().toIso8601String(),
      'products': await db.query('products'),
      'entries': await db.query('entries'),
      'closes': await db.query('closes'),
      'closeItems': await db.query('close_items'),
      'movements': await db.query('inventory_movements'),
    };
    return Uint8List.fromList(utf8.encode(jsonEncode(payload)));
  }

  Future<void> restoreBackup(Uint8List bytes) async {
    final Object? decoded;
    try {
      decoded = jsonDecode(utf8.decode(bytes));
    } on FormatException {
      throw const FormatException('El archivo no contiene un respaldo válido.');
    }
    if (decoded is! Map<String, dynamic> ||
        decoded['format'] != 'flowstock-backup' ||
        decoded['formatVersion'] != formatVersion) {
      throw const FormatException('El formato del respaldo no es compatible.');
    }

    final products = _rows(decoded, 'products');
    final entries = _rows(decoded, 'entries');
    final closes = _rows(decoded, 'closes');
    final closeItems = _rows(decoded, 'closeItems');
    final movements = _rows(decoded, 'movements', optional: true);

    final db = await _databaseHelper.database;
    await db.transaction((txn) async {
      await txn.delete('inventory_movements');
      await txn.delete('close_items');
      await txn.delete('closes');
      await txn.delete('entries');
      await txn.delete('products');

      for (final row in products) {
        await txn.insert('products', row);
      }
      for (final row in entries) {
        await txn.insert('entries', row);
      }
      for (final row in closes) {
        await txn.insert('closes', row);
      }
      for (final row in closeItems) {
        await txn.insert('close_items', row);
      }
      for (final row in movements) {
        await txn.insert('inventory_movements', row);
      }
    });
  }

  List<Map<String, Object?>> _rows(
    Map<String, dynamic> payload,
    String key, {
    bool optional = false,
  }) {
    final value = payload[key];
    if (optional && value == null) return const [];
    if (value is! List) {
      throw FormatException('Falta la sección requerida: $key.');
    }
    return value.map((row) {
      if (row is! Map) {
        throw FormatException('La sección $key contiene datos inválidos.');
      }
      return row.map(
        (key, value) => MapEntry(key.toString(), value as Object?),
      );
    }).toList();
  }
}
