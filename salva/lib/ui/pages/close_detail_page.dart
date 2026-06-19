import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cafeteria_flutter/providers/inventory_provider.dart';
import 'package:cafeteria_flutter/models/close_item.dart';
import 'package:intl/intl.dart';

class CloseDetailPage extends StatelessWidget {
  final String date;

  const CloseDetailPage({super.key, required this.date});

  @override
  Widget build(BuildContext context) {
    final currencyFormat = NumberFormat.currency(symbol: r'$', decimalDigits: 2);
    final theme = Theme.of(context);
    
    DateTime dateObj = DateTime.parse(date);
    String fullDate = DateFormat('EEEE, d MMMM yyyy', 'es').format(dateObj);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Resumen del Día', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: const BoxDecoration(
              color: Colors.white,
              border: Border(bottom: BorderSide(color: Color(0xFFE5E7EB))),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  fullDate.toUpperCase(),
                  style: const TextStyle(
                    color: Color(0xFFF4B740),
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.2,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Detalle de Ventas',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF181A1F)),
                ),
              ],
            ),
          ),
          Expanded(
            child: FutureBuilder<List<CloseItem>>(
              future: context.read<InventoryProvider>().getCloseItems(date),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return const Center(child: Text('No hay detalles para este cierre.', style: TextStyle(color: Color(0xFF717680))));
                }
                
                final items = snapshot.data!;
                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: items.length,
                  itemBuilder: (context, index) {
                    final item = items[index];
                    if (item.soldUnits == 0) return const SizedBox.shrink();

                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Text(
                                    item.productName,
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF181A1F)),
                                  ),
                                ),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Text(
                                      currencyFormat.format(item.profit),
                                      style: const TextStyle(
                                        color: Color(0xFF16A365),
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                      ),
                                    ),
                                    const Text('ganancia', style: TextStyle(fontSize: 10, color: Color(0xFF717680))),
                                  ],
                                ),
                              ],
                            ),
                            const Padding(
                              padding: EdgeInsets.symmetric(vertical: 12),
                              child: Divider(height: 1, color: Color(0xFFF5F6F8)),
                            ),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                _DetailInfo(label: 'INICIAL', value: item.initialQty.toString()),
                                _DetailInfo(label: 'FINAL', value: item.finalQty.toString()),
                                _DetailInfo(
                                  label: 'VENDIDO', 
                                  value: item.soldUnits.toString(),
                                  highlightColor: theme.colorScheme.primary,
                                ),
                                _DetailInfo(
                                  label: 'INGRESO', 
                                  value: currencyFormat.format(item.revenue),
                                  isCurrency: true,
                                ),
                              ],
                            ),
                          ],
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
    );
  }
}

class _DetailInfo extends StatelessWidget {
  final String label;
  final String value;
  final Color? highlightColor;
  final bool isCurrency;

  const _DetailInfo({
    required this.label, 
    required this.value, 
    this.highlightColor,
    this.isCurrency = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          label,
          style: const TextStyle(color: Color(0xFF717680), fontSize: 9, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: isCurrency ? 13 : 15,
            color: highlightColor ?? const Color(0xFF181A1F),
          ),
        ),
      ],
    );
  }
}
