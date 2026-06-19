import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:cafeteria_flutter/models/entry.dart';
import 'package:cafeteria_flutter/providers/inventory_provider.dart';
import 'package:cafeteria_flutter/ui/theme/app_theme.dart';
import 'package:cafeteria_flutter/ui/widgets/app_ui.dart';

class EntryHistoryPage extends StatefulWidget {
  const EntryHistoryPage({super.key});

  @override
  State<EntryHistoryPage> createState() => _EntryHistoryPageState();
}

class _EntryHistoryPageState extends State<EntryHistoryPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<InventoryProvider>().fetchEntries();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Historial de entradas')),
      body: Consumer<InventoryProvider>(
        builder: (context, provider, _) {
          if (provider.entries.isEmpty) {
            return const AppEmptyState(
              icon: Icons.history_rounded,
              title: 'Sin entradas registradas',
              message:
                  'Aquí aparecerán todas las entradas de mercancía que realices.',
            );
          }

          final totalUnits = provider.entries.fold<int>(
            0,
            (sum, entry) => sum + entry.quantity,
          );

          return RefreshIndicator(
            onRefresh: provider.fetchEntries,
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 30),
              children: [
                _HistorySummary(
                  movements: provider.entries.length,
                  units: totalUnits,
                ),
                const SizedBox(height: 24),
                const AppSectionHeader(title: 'Movimientos recientes'),
                const SizedBox(height: 12),
                ...provider.entries.map(
                  (entry) => Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: _EntryCard(
                      entry: entry,
                      onDelete: () => _confirmDelete(context, entry),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Future<void> _confirmDelete(BuildContext context, Entry entry) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Eliminar entrada'),
        content: Text(
          'Se restarán ${entry.quantity} unidades del stock actual de “${entry.productName}”.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text(
              'Eliminar',
              style: TextStyle(color: AppColors.danger),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      await context.read<InventoryProvider>().deleteEntry(entry);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Entrada eliminada y stock corregido.')),
      );
    }
  }
}

class _HistorySummary extends StatelessWidget {
  final int movements;
  final int units;

  const _HistorySummary({required this.movements, required this.units});

  @override
  Widget build(BuildContext context) {
    return AppSurface(
      color: AppColors.graphite,
      border: const Border(),
      padding: const EdgeInsets.all(19),
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: Colors.white.withAlpha(18),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(
              Icons.move_to_inbox_rounded,
              color: AppColors.amber,
              size: 22,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: _DarkMetric(label: 'Movimientos', value: '$movements'),
          ),
          Container(width: 1, height: 36, color: Colors.white12),
          const SizedBox(width: 18),
          Expanded(
            child: _DarkMetric(label: 'Unidades', value: '$units'),
          ),
        ],
      ),
    );
  }
}

class _DarkMetric extends StatelessWidget {
  final String label;
  final String value;

  const _DarkMetric({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 19,
            fontWeight: FontWeight.w800,
          ),
        ),
        Text(
          label,
          style: const TextStyle(color: Colors.white54, fontSize: 11),
        ),
      ],
    );
  }
}

class _EntryCard extends StatelessWidget {
  final Entry entry;
  final VoidCallback onDelete;

  const _EntryCard({required this.entry, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    final date = DateTime.fromMillisecondsSinceEpoch(entry.timestamp);
    final formatted = DateFormat('d MMM yyyy · h:mm a', 'es').format(date);

    return AppSurface(
      padding: const EdgeInsets.all(15),
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: AppColors.successSoft,
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(
              Icons.add_rounded,
              color: AppColors.success,
              size: 23,
            ),
          ),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  entry.productName,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 3),
                Text(formatted, style: Theme.of(context).textTheme.bodySmall),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '+${entry.quantity}',
                style: const TextStyle(
                  color: AppColors.success,
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const Text(
                'unidades',
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 10,
                ),
              ),
            ],
          ),
          IconButton(
            onPressed: onDelete,
            tooltip: 'Eliminar entrada',
            icon: const Icon(
              Icons.delete_outline_rounded,
              color: AppColors.textSecondary,
              size: 20,
            ),
          ),
        ],
      ),
    );
  }
}
