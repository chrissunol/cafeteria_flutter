import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cafeteria_flutter/providers/inventory_provider.dart';
import 'package:cafeteria_flutter/ui/pages/close_detail_page.dart';
import 'package:intl/intl.dart';

class HistoryPage extends StatefulWidget {
  const HistoryPage({super.key});

  @override
  State<HistoryPage> createState() => _HistoryPageState();
}

class _HistoryPageState extends State<HistoryPage> {
  @override
  void initState() {
    super.initState();
    context.read<InventoryProvider>().fetchCloses();
  }

  @override
  Widget build(BuildContext context) {
    final currencyFormat =
        NumberFormat.currency(symbol: r'$', decimalDigits: 2);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Reportes',
            style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: Consumer<InventoryProvider>(
        builder: (context, provider, child) {
          if (provider.closes.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(40.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.history_rounded,
                        size: 80, color: Color(0xFFE5E7EB)),
                    const SizedBox(height: 16),
                    const Text(
                      'Todavía no hay cierres',
                      style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                          color: Color(0xFF181A1F)),
                    ),
                    const Text(
                      'Cuando realices tu primer cierre diario, aparecerá aquí el historial de ventas y ganancias.',
                      style: TextStyle(color: Color(0xFF717680)),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 32),
                    ElevatedButton.icon(
                      onPressed: () =>
                          DefaultTabController.of(context).animateTo(3),
                      icon: const Icon(Icons.receipt_long_rounded),
                      label: const Text('Hacer mi primer cierre'),
                    ),
                  ],
                ),
              ),
            );
          }

          double totalHistoricalProfit =
              provider.closes.fold(0, (sum, item) => sum + item.totalProfit);
          double totalHistoricalRevenue =
              provider.closes.fold(0, (sum, item) => sum + item.totalRevenue);

          return CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary,
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: theme.colorScheme.primary.withAlpha(40),
                          blurRadius: 15,
                          offset: const Offset(0, 8),
                        )
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Ganancia Total Acumulada',
                          style: TextStyle(color: Colors.white70, fontSize: 14),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          currencyFormat.format(totalHistoricalProfit),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                            letterSpacing: -1,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            _HeaderStat(
                              label: 'Ventas Totales',
                              value:
                                  currencyFormat.format(totalHistoricalRevenue),
                            ),
                            const SizedBox(width: 24),
                            _HeaderStat(
                              label: 'Días Cerrados',
                              value: provider.closes.length.toString(),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final c = provider.closes[index];
                      DateTime dateObj = DateTime.parse(c.date);
                      String dayNum = DateFormat('d').format(dateObj);
                      String monthName =
                          DateFormat('MMM', 'es').format(dateObj).toUpperCase();

                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        child: InkWell(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (context) =>
                                      CloseDetailPage(date: c.date)),
                            );
                          },
                          borderRadius: BorderRadius.circular(16),
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Row(
                              children: [
                                Container(
                                  width: 54,
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 8),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFF5F6F8),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                        color: const Color(0xFFE5E7EB)),
                                  ),
                                  child: Column(
                                    children: [
                                      Text(
                                        dayNum,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 18,
                                          color: Color(0xFF181A1F),
                                        ),
                                      ),
                                      Text(
                                        monthName,
                                        style: const TextStyle(
                                          fontSize: 10,
                                          fontWeight: FontWeight.bold,
                                          color: Color(0xFF17181C),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        'Cierre del día',
                                        style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 15,
                                            color: Color(0xFF181A1F)),
                                      ),
                                      Text(
                                        '${c.totalSoldUnits} unidades vendidas',
                                        style: const TextStyle(
                                            color: Color(0xFF717680),
                                            fontSize: 13),
                                      ),
                                    ],
                                  ),
                                ),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Text(
                                      currencyFormat.format(c.totalProfit),
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                        color: Color(0xFF16A365),
                                      ),
                                    ),
                                    const Text(
                                      'ganancia',
                                      style: TextStyle(
                                          fontSize: 11,
                                          color: Color(0xFF717680)),
                                    ),
                                  ],
                                ),
                                const SizedBox(width: 4),
                                const Icon(Icons.chevron_right_rounded,
                                    color: Color(0xFFE5E7EB)),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                    childCount: provider.closes.length,
                  ),
                ),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: 20)),
            ],
          );
        },
      ),
    );
  }
}

class _HeaderStat extends StatelessWidget {
  final String label;
  final String value;

  const _HeaderStat({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(color: Colors.white70, fontSize: 12)),
        Text(
          value,
          style: const TextStyle(
              color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
        ),
      ],
    );
  }
}
