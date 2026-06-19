import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cafeteria_flutter/providers/inventory_provider.dart';
import 'package:intl/intl.dart';

class EntryHistoryPage extends StatefulWidget {
  const EntryHistoryPage({super.key});

  @override
  State<EntryHistoryPage> createState() => _EntryHistoryPageState();
}

class _EntryHistoryPageState extends State<EntryHistoryPage> {
  @override
  void initState() {
    super.initState();
    context.read<InventoryProvider>().fetchEntries();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Historial de Stock',
            style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: Consumer<InventoryProvider>(
        builder: (context, provider, child) {
          if (provider.entries.isEmpty) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(40.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.history_rounded,
                        size: 80, color: Color(0xFFE5E7EB)),
                    SizedBox(height: 16),
                    Text(
                      'Sin movimientos de stock',
                      style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                          color: Color(0xFF181A1F)),
                    ),
                    Text(
                      'Aquí verás todas las veces que agregaste mercancía al inventario.',
                      style: TextStyle(color: Color(0xFF717680)),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: provider.entries.length,
            itemBuilder: (context, index) {
              final e = provider.entries[index];
              final date = DateTime.fromMillisecondsSinceEpoch(e.timestamp);
              final formattedDate =
                  DateFormat('EEE, d MMM - HH:mm').format(date);

              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: ListTile(
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  leading: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFF16A365).withAlpha(15),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.add_shopping_cart_rounded,
                        color: Color(0xFF16A365), size: 20),
                  ),
                  title: Text(e.productName,
                      style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF181A1F))),
                  subtitle: Text('+${e.quantity} unidades • $formattedDate',
                      style: const TextStyle(color: Color(0xFF717680))),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete_outline_rounded,
                        color: Color(0xFFDC4C4C)),
                    onPressed: () => _confirmDelete(context, e),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  void _confirmDelete(BuildContext context, dynamic e) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Eliminar Registro'),
        content: const Text(
            '¿Estás seguro? Se restará esta cantidad del stock actual del producto para corregir el inventario.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar',
                  style: TextStyle(color: Color(0xFF717680)))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFDC4C4C),
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              context.read<InventoryProvider>().deleteEntry(e);
              Navigator.pop(context);
            },
            child: const Text('ELIMINAR'),
          ),
        ],
      ),
    );
  }
}
