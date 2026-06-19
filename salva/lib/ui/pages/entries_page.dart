import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cafeteria_flutter/providers/inventory_provider.dart';

import 'package:cafeteria_flutter/ui/pages/entry_history_page.dart';

class EntriesPage extends StatefulWidget {
  const EntriesPage({super.key});

  @override
  State<EntriesPage> createState() => _EntriesPageState();
}

class _EntriesPageState extends State<EntriesPage> {
  final Map<int, int> _deltas = {};
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
    return Scaffold(
      appBar: AppBar(
        title: const Text('Abastecer Stock',
            style: TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            icon: const Icon(Icons.history_rounded),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const EntryHistoryPage()),
            ),
          ),
          const SizedBox(width: 8),
        ],
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
                hintText: 'Buscar producto para abastecer...',
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
                          const Icon(Icons.local_shipping_outlined,
                              size: 64, color: Color(0xFFE5E7EB)),
                          const SizedBox(height: 16),
                          Text(
                            _searchQuery.isEmpty
                                ? 'Todavía no hay productos para abastecer'
                                : 'No encontramos ese producto',
                            style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF181A1F)),
                          ),
                          if (_searchQuery.isEmpty) ...[
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () =>
                                  DefaultTabController.of(context).animateTo(1),
                              child: const Text('Ir a agregar productos'),
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
                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: ListTile(
                          title: Text(p.name,
                              style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF181A1F))),
                          subtitle: Text('Stock actual: ${p.quantity}',
                              style: const TextStyle(color: Color(0xFF717680))),
                          trailing: SizedBox(
                            width: 90,
                            child: TextField(
                              decoration: const InputDecoration(
                                labelText: 'Cant.',
                                contentPadding: EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 8),
                                isDense: true,
                              ),
                              keyboardType: TextInputType.number,
                              onChanged: (val) {
                                final qty = int.tryParse(val);
                                if (qty != null && qty > 0) {
                                  _deltas[p.id!] = qty;
                                } else {
                                  _deltas.remove(p.id);
                                }
                              },
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: const BoxDecoration(
            color: Colors.white,
            border: Border(top: BorderSide(color: Color(0xFFE5E7EB))),
          ),
          child: ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              minimumSize: const Size(double.infinity, 56),
            ),
            icon: const Icon(Icons.save_rounded),
            label: const Text('REGISTRAR ENTRADA DE STOCK',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            onPressed: _saveEntries,
          ),
        ),
      ),
    );
  }

  void _saveEntries() async {
    _deltas.removeWhere((key, value) => value <= 0);

    if (_deltas.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text(
          'Por favor, ingresa cuánto stock estás agregando.',
          style: TextStyle(color: Color(0xFF17181C)),
        ),
        backgroundColor: Color(0xFFF4B740),
      ));
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Confirmar Entrada'),
        content: Text(
            'Se agregarán las cantidades a ${_deltas.length} productos. ¿Confirmas la operación?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancelar',
                  style: TextStyle(color: Color(0xFF717680)))),
          TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Confirmar',
                  style: TextStyle(fontWeight: FontWeight.bold))),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      try {
        await context.read<InventoryProvider>().addEntries(_deltas);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('Stock actualizado con éxito.'),
            backgroundColor: Color(0xFF16A365),
          ));
          setState(() {
            _deltas.clear();
            _searchCtrl.clear();
            _searchQuery = '';
          });
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content: Text('Error: $e'),
                backgroundColor: const Color(0xFFDC4C4C)),
          );
        }
      }
    }
  }
}
