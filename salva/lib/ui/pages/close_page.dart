import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cafeteria_flutter/providers/inventory_provider.dart';
import 'package:intl/intl.dart';

class ClosePage extends StatefulWidget {
  const ClosePage({super.key});

  @override
  State<ClosePage> createState() => _ClosePageState();
}

class _ClosePageState extends State<ClosePage> {
  final Map<int, int> _finals = {};
  final String _todayStr = DateFormat('yyyy-MM-dd').format(DateTime.now());
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
        title: const Text('Cierre Diario', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.fromLTRB(20, 10, 20, 24),
            decoration: const BoxDecoration(
              color: Colors.white,
              border: Border(bottom: BorderSide(color: Color(0xFFE5E7EB))),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Cierre de Caja',
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF181A1F)),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF4B740).withAlpha(20),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        _todayStr,
                        style: const TextStyle(color: Color(0xFF17181C), fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _searchCtrl,
                  onChanged: (val) => setState(() => _searchQuery = val.toLowerCase()),
                  decoration: const InputDecoration(
                    hintText: 'Buscar producto para contar...',
                    prefixIcon: Icon(Icons.search_rounded),
                  ),
                ),
              ],
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
                    child: Text('No hay productos que coincidan', style: TextStyle(color: Colors.grey[500])),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: filteredProducts.length,
                  itemBuilder: (context, index) {
                    final p = filteredProducts[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: ListTile(
                          title: Text(p.name, style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF181A1F))),
                          subtitle: Text('Debería haber: ${p.quantity}', style: const TextStyle(color: Color(0xFF717680))),
                          trailing: SizedBox(
                            width: 100,
                            child: TextField(
                              decoration: InputDecoration(
                                labelText: 'Quedan',
                                hintText: p.quantity.toString(),
                                isDense: true,
                              ),
                              keyboardType: TextInputType.number,
                              onChanged: (val) {
                                _finals[p.id!] = int.tryParse(val) ?? p.quantity;
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
            icon: const Icon(Icons.check_circle_rounded),
            label: const Text('REALIZAR CIERRE DIARIO', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            onPressed: _doClose,
          ),
        ),
      ),
    );
  }

  void _doClose() async {
    final provider = context.read<InventoryProvider>();
    bool exists = await provider.checkCloseExists(_todayStr);
    bool shouldUpdate = false;
    
    if (exists) {
      final confirmUpdate = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text('Cierre ya registrado'),
          content: const Text('Ya existe un cierre para hoy. ¿Deseas actualizarlo con los nuevos datos contados?'),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancelar', style: TextStyle(color: Color(0xFF717680)))),
            TextButton(
              onPressed: () => Navigator.pop(context, true), 
              child: const Text('Actualizar', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFFF4B740)))
            ),
          ],
        ),
      );
      if (confirmUpdate != true) return;
      shouldUpdate = true;
    } else {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text('Confirmar Cierre'),
          content: const Text('Se calcularán las ventas basándose en lo que queda. Asegúrate de haber contado bien.'),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancelar', style: TextStyle(color: Color(0xFF717680)))),
            TextButton(
              onPressed: () => Navigator.pop(context, true), 
              child: const Text('Hacer Cierre', style: TextStyle(fontWeight: FontWeight.bold))
            ),
          ],
        ),
      );
      if (confirmed != true) return;
    }

    if (mounted) {
      try {
        if (shouldUpdate) {
          await provider.updateClose(_todayStr, _finals);
        } else {
          await provider.generateClose(_todayStr, _finals);
        }
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(shouldUpdate ? 'Cierre actualizado' : 'Cierre completado con éxito'),
              backgroundColor: const Color(0xFF16A365),
            )
          );
          DefaultTabController.of(context).animateTo(4); // Ir a reportes
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: ${e.toString()}'), backgroundColor: const Color(0xFFDC4C4C)),
          );
        }
      }
    }
  }
}
