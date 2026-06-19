import 'package:flutter/material.dart';
import 'package:cafeteria_flutter/data/inventory_repository.dart';
import 'package:cafeteria_flutter/models/product.dart';
import 'package:cafeteria_flutter/models/entry.dart';
import 'package:cafeteria_flutter/models/close.dart';
import 'package:cafeteria_flutter/models/close_item.dart';

class InventoryProvider extends ChangeNotifier {
  final InventoryRepository _repository = InventoryRepository();

  double _totalInvestment = 0.0;
  int _productCount = 0;
  double _avgProfit = 0.0;
  List<Product> _products = [];
  List<Entry> _entries = [];
  List<Close> _closes = [];

  double get totalInvestment => _totalInvestment;
  int get productCount => _productCount;
  double get avgProfit => _avgProfit;
  List<Product> get products => _products;
  List<Entry> get entries => _entries;
  List<Close> get closes => _closes;

  Future<void> refreshHomeStats() async {
    _totalInvestment = await _repository.getTotalInvestment();
    _productCount = await _repository.getProductCount();
    _avgProfit = await _repository.getAvgDailyProfit();
    notifyListeners();
  }

  Future<void> fetchProducts() async {
    _products = await _repository.getAllProducts();
    notifyListeners();
  }

  Future<void> fetchEntries() async {
    _entries = await _repository.getAllEntries();
    notifyListeners();
  }

  Future<void> fetchCloses() async {
    _closes = await _repository.getAllCloses();
    notifyListeners();
  }

  Future<void> upsertProduct(Product product) async {
    await _repository.upsertProduct(product);
    await fetchProducts();
    await refreshHomeStats();
  }

  Future<void> deleteProduct(int id) async {
    await _repository.deleteProduct(id);
    await fetchProducts();
    await refreshHomeStats();
  }

  Future<bool> hasHistory(int productId) async {
    // Check in entries
    if (_entries.isEmpty) await fetchEntries();
    if (_entries.any((e) => e.productId == productId)) return true;
    
    // Check in closures
    return await _repository.productUsedInCloses(productId);
  }

  Future<void> addEntries(Map<int, int> deltaByProductId) async {
    await _repository.addEntries(deltaByProductId);
    await fetchProducts();
    await fetchEntries();
    await refreshHomeStats();
  }

  Future<void> deleteEntry(Entry entry) async {
    await _repository.deleteEntry(entry);
    await fetchProducts();
    await fetchEntries();
    await refreshHomeStats();
  }

  Future<void> generateClose(String date, Map<int, int> finalQtyByProductId) async {
    await _repository.generateClose(date, finalQtyByProductId);
    await fetchProducts();
    await fetchCloses();
    await refreshHomeStats();
  }

  Future<void> updateClose(String date, Map<int, int> finalQtyByProductId) async {
    await _repository.updateClose(date, finalQtyByProductId);
    await fetchProducts();
    await fetchCloses();
    await refreshHomeStats();
  }
  
  Future<List<CloseItem>> getCloseItems(String date) async {
    return await _repository.getCloseItems(date);
  }

  Future<bool> checkCloseExists(String date) async {
    return await _repository.closeExists(date);
  }
}
