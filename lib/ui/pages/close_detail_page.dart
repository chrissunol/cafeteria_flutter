import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:cafeteria_flutter/models/close_item.dart';
import 'package:cafeteria_flutter/providers/inventory_provider.dart';
import 'package:cafeteria_flutter/ui/theme/app_theme.dart';
import 'package:cafeteria_flutter/ui/widgets/app_ui.dart';

class CloseDetailPage extends StatelessWidget {
  final String date;

  const CloseDetailPage({super.key, required this.date});

  @override
  Widget build(BuildContext context) {
    final money = NumberFormat.currency(symbol: r'$', decimalDigits: 2);
    final dateObject = DateTime.parse(date);
    final rawDate = DateFormat('EEEE, d MMMM yyyy', 'es').format(dateObject);
    final fullDate = rawDate.isEmpty
        ? rawDate
        : '${rawDate[0].toUpperCase()}${rawDate.substring(1)}';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Detalle del cierre'),
      ),
      body: FutureBuilder<List<CloseItem>>(
        future: context.read<InventoryProvider>().getCloseItems(date),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return AppEmptyState(
              icon: Icons.error_outline_rounded,
              title: 'No pudimos cargar el cierre',
              message: snapshot.error.toString(),
            );
          }

          final allItems = snapshot.data ?? const <CloseItem>[];
          final soldItems = allItems.where((item) => item.soldUnits > 0).toList();
          final soldUnits = allItems.fold<int>(
            0,
            (sum, item) => sum + item.soldUnits,
          );
          final revenue = allItems.fold<double>(
            0,
            (sum, item) => sum + item.revenue,
          );
          final profit = allItems.fold<double>(
            0,
            (sum, item) => sum + item.profit,
          );

          return ListView(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 30),
            children: [
              Text(
                fullDate,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 8),
              Text(
                'Resumen del día',
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: 18),
              _CloseSummary(
                revenue: money.format(revenue),
                profit: money.format(profit),
                soldUnits: soldUnits,
              ),
              const SizedBox(height: 28),
              AppSectionHeader(
                title: 'Productos vendidos',
                actionLabel: soldItems.isEmpty
                    ? null
                    : '${soldItems.length} productos',
              ),
              const SizedBox(height: 12),
              if (soldItems.isEmpty)
                const AppSurface(
                  padding: EdgeInsets.all(22),
                  child: Row(
                    children: [
                      Icon(
                        Icons.info_outline_rounded,
                        color: AppColors.textSecondary,
                      ),
                      SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Este cierre no registró unidades vendidas.',
                          style: TextStyle(color: AppColors.textSecondary),
                        ),
                      ),
                    ],
                  ),
                )
              else
                ...soldItems.map(
                  (item) => Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: _SoldProductCard(
                      item: item,
                      revenue: money.format(item.revenue),
                      profit: money.format(item.profit),
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}

class _CloseSummary extends StatelessWidget {
  final String revenue;
  final String profit;
  final int soldUnits;

  const _CloseSummary({
    required this.revenue,
    required this.profit,
    required this.soldUnits,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: AppColors.graphite,
        borderRadius: BorderRadius.circular(22),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'INGRESOS DEL DÍA',
            style: TextStyle(
              color: Colors.white60,
              fontSize: 11,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.15,
            ),
          ),
          const SizedBox(height: 10),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              revenue,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 34,
                fontWeight: FontWeight.w800,
                letterSpacing: -1,
              ),
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: _SummaryMetric(
                  label: 'Ganancia',
                  value: profit,
                  valueColor: AppColors.amber,
                ),
              ),
              Expanded(
                child: _SummaryMetric(
                  label: 'Unidades',
                  value: '$soldUnits',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SummaryMetric extends StatelessWidget {
  final String label;
  final String value;
  final Color valueColor;

  const _SummaryMetric({
    required this.label,
    required this.value,
    this.valueColor = Colors.white,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          value,
          style: TextStyle(
            color: valueColor,
            fontSize: 17,
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

class _SoldProductCard extends StatelessWidget {
  final CloseItem item;
  final String revenue;
  final String profit;

  const _SoldProductCard({
    required this.item,
    required this.revenue,
    required this.profit,
  });

  @override
  Widget build(BuildContext context) {
    return AppSurface(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: AppColors.amberSoft,
                  borderRadius: BorderRadius.circular(13),
                ),
                child: const Icon(
                  Icons.shopping_bag_outlined,
                  color: AppColors.graphite,
                  size: 20,
                ),
              ),
              const SizedBox(width: 13),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.productName,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    Text(
                      '${item.soldUnits} unidades vendidas',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    profit,
                    style: const TextStyle(
                      color: AppColors.success,
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const Text(
                    'ganancia',
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 10,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 15),
          const Divider(),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _ProductMetric(
                  label: 'Inicial',
                  value: '${item.initialQty}',
                ),
              ),
              Expanded(
                child: _ProductMetric(
                  label: 'Final',
                  value: '${item.finalQty}',
                ),
              ),
              Expanded(
                child: _ProductMetric(
                  label: 'Vendido',
                  value: '${item.soldUnits}',
                  color: AppColors.textPrimary,
                ),
              ),
              Expanded(
                child: _ProductMetric(
                  label: 'Ingreso',
                  value: revenue,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ProductMetric extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _ProductMetric({
    required this.label,
    required this.value,
    this.color = AppColors.textPrimary,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            value,
            maxLines: 1,
            style: TextStyle(
              color: color,
              fontSize: 13,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        const SizedBox(height: 3),
        Text(
          label,
          style: const TextStyle(
            color: AppColors.textSecondary,
            fontSize: 10,
          ),
        ),
      ],
    );
  }
}
