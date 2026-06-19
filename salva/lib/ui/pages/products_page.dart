import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cafeteria_flutter/providers/inventory_provider.dart';
import 'package:cafeteria_flutter/models/product.dart';
import 'package:intl/intl.dart';

class ProductsPage extends StatefulWidget {
  const ProductsPage({super.key});

  @override
  State<ProductsPage> createState() => _ProductsPageState();
}

class _ProductsPageState extends State<ProductsPage> {
  final TextEditingController _searchCtrl = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    context.read<InventoryProvider>().fetchProducts();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final currencyFormat =
        NumberFormat.currency(symbol: r'$', decimalDigits: 2);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Inventario',
            style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchCtrl,
              onChanged: (val) =>
                  setState(() => _searchQuery = val.toLowerCase()),
              decoration: InputDecoration(
                hintText: 'Buscar producto...',
                prefixIcon: const Icon(Icons.search_rounded),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear_rounded),
                        onPressed: () {
                          _searchCtrl.clear();
                          setState(() => _searchQuery = '');
                        },
                      )
                    : null,
              ),
            ),
          ),
          Expanded(
            child: Consumer<InventoryProvider>(
              builder: (context, provider, child) {
                final filteredProducts = provider.products
                    .where((p) => p.name.toLowerCase().contains(_searchQuery))
                    .toList();

                if (filteredProducts.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(40.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.inventory_2_outlined,
                              size: 80, color: Color(0xFFE5E7EB)),
                          const SizedBox(height: 24),
                          Text(
                            _searchQuery.isEmpty
                                ? 'Todavía no hay productos'
                                : 'No se encontró el producto',
                            style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 18,
                                color: Color(0xFF181A1F)),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            _searchQuery.isEmpty
                                ? 'Agrega tu primer producto para empezar a controlar el inventario de la cafetería.'
                                : 'Prueba buscando con otro nombre o agrega uno nuevo.',
                            style: const TextStyle(color: Color(0xFF717680)),
                            textAlign: TextAlign.center,
                          ),
                          if (_searchQuery.isEmpty) ...[
                            const SizedBox(height: 32),
                            ElevatedButton.icon(
                              onPressed: () =>
                                  _showProductDialog(context, null),
                              icon: const Icon(Icons.add),
                              label: const Text('Agregar producto'),
                            ),
                          ],
                        ],
                      ),
                    ),
                  );
                }
                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: filteredProducts.length,
                  itemBuilder: (context, index) {
                    final p = filteredProducts[index];
                    final isLowStock = p.quantity <= p.minStock;

                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 4),
                        title: Text(p.name,
                            style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                                color: Color(0xFF181A1F))),
                        subtitle: Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: isLowStock
                                      ? const Color(0xFFDC4C4C).withAlpha(20)
                                      : const Color(0xFF16A365).withAlpha(20),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  'Stock: ${p.quantity}',
                                  style: TextStyle(
                                    color: isLowStock
                                        ? const Color(0xFFDC4C4C)
                                        : const Color(0xFF16A365),
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Text(
                                'Venta: ${currencyFormat.format(p.salePrice)}',
                                style: const TextStyle(
                                    color: Color(0xFF717680), fontSize: 13),
                              ),
                            ],
                          ),
                        ),
                        trailing: IconButton(
                          icon: const Icon(Icons.edit_outlined,
                              color: Color(0xFFF4B740)),
                          onPressed: () => _showProductDialog(context, p),
                        ),
                        onLongPress: () => _confirmDelete(context, p),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showProductDialog(context, null),
        child: const Icon(Icons.add_rounded),
      ),
    );
  }

  void _showProductDialog(BuildContext context, Product? p) {
    final nameCtrl = TextEditingController(text: p?.name ?? '');
    final costCtrl = TextEditingController(text: p?.costPrice.toString() ?? '');
    final saleCtrl = TextEditingController(text: p?.salePrice.toString() ?? '');
    final qtyCtrl = TextEditingController(text: p?.quantity.toString() ?? '0');
    final minCtrl = TextEditingController(text: p?.minStock.toString() ?? '5');

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        backgroundColor: Colors.white,
        title: Text(p == null ? 'Nuevo Producto' : 'Editar Producto'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildField(
                  nameCtrl, 'Nombre del producto', Icons.coffee_rounded),
              _buildField(costCtrl, 'Precio de Costo', Icons.input_rounded,
                  isNumber: true),
              _buildField(saleCtrl, 'Precio de Venta', Icons.sell_outlined,
                  isNumber: true),
              _buildField(qtyCtrl, 'Cantidad Actual', Icons.numbers_rounded,
                  isNumber: true),
              _buildField(minCtrl, 'Stock Mínimo Aviso',
                  Icons.notifications_active_outlined,
                  isNumber: true),
            ],
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar',
                  style: TextStyle(color: Color(0xFF717680)))),
          ElevatedButton(
            onPressed: () {
              final name = nameCtrl.text.trim();
              final cost = double.tryParse(costCtrl.text) ?? 0.0;
              final sale = double.tryParse(saleCtrl.text) ?? 0.0;
              final qty = int.tryParse(qtyCtrl.text) ?? 0;
              final min = int.tryParse(minCtrl.text) ?? 0;

              if (name.isEmpty) {
                _showError(context, 'El nombre es obligatorio.');
                return;
              }

              final provider = context.read<InventoryProvider>();
              bool isDuplicate = provider.products.any((element) =>
                  element.name.toLowerCase() == name.toLowerCase() &&
                  element.id != p?.id);
              if (isDuplicate) {
                _showError(context, 'Ya existe un producto con este nombre.');
                return;
              }

              if (cost < 0 || sale < 0) {
                _showError(context, 'Los precios no pueden ser negativos.');
                return;
              }

              final newP = Product(
                id: p?.id,
                name: name,
                costPrice: cost,
                salePrice: sale,
                quantity: qty,
                minStock: min,
                updatedAt: DateTime.now().millisecondsSinceEpoch,
              );
              provider.upsertProduct(newP);
              Navigator.pop(context);

              ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                content: Text(
                    p == null ? 'Producto guardado' : 'Producto actualizado'),
                backgroundColor: const Color(0xFF16A365),
              ));
            },
            child: const Text('Guardar'),
          ),
        ],
      ),
    );
  }

  void _showError(BuildContext context, String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(msg), backgroundColor: const Color(0xFFDC4C4C)));
  }

  Widget _buildField(TextEditingController ctrl, String label, IconData icon,
      {bool isNumber = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextField(
        controller: ctrl,
        keyboardType: isNumber
            ? const TextInputType.numberWithOptions(decimal: true)
            : TextInputType.text,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon, size: 20),
        ),
      ),
    );
  }

  void _confirmDelete(BuildContext context, Product p) async {
    if (!mounted) return;

    final provider = context.read<InventoryProvider>();
    final hasHistory = await provider.hasHistory(p.id!);

    if (!mounted) return;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Eliminar Producto'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('¿Seguro que quieres eliminar "${p.name}"?'),
            if (hasHistory) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFDC4C4C).withAlpha(10),
                  borderRadius: BorderRadius.circular(12),
                  border:
                      Border.all(color: const Color(0xFFDC4C4C).withAlpha(30)),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.warning_amber_rounded,
                        color: Color(0xFFDC4C4C), size: 18),
                    SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Este producto tiene historial. Borrarlo afectará los reportes anteriores.',
                        style:
                            TextStyle(fontSize: 12, color: Color(0xFFDC4C4C)),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar',
                  style: TextStyle(color: Color(0xFF717680)))),
          TextButton(
            onPressed: () {
              provider.deleteProduct(p.id!);
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Producto eliminado')));
            },
            child: const Text('Eliminar',
                style: TextStyle(
                    color: Color(0xFFDC4C4C), fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}
