import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:cafeteria_flutter/models/product.dart';
import 'package:cafeteria_flutter/providers/inventory_provider.dart';
import 'package:cafeteria_flutter/ui/theme/app_theme.dart';
import 'package:cafeteria_flutter/ui/widgets/app_ui.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _refresh());
  }

  Future<void> _refresh() async {
    final provider = context.read<InventoryProvider>();
    await Future.wait([
      provider.refreshHomeStats(),
      provider.fetchProducts(),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    final money = NumberFormat.currency(symbol: r'$', decimalDigits: 2);
    final rawDate = DateFormat('EEEE, d MMMM', 'es').format(DateTime.now());
    final formattedDate = rawDate.isEmpty
        ? rawDate
        : '${rawDate[0].toUpperCase()}${rawDate.substring(1)}';

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Consumer<InventoryProvider>(
          builder: (context, provider, _) {
            final lowStock = provider.products
                .where((product) => product.quantity <= product.minStock)
                .toList()
              ..sort((a, b) => a.quantity.compareTo(b.quantity));

            return RefreshIndicator(
              onRefresh: _refresh,
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(20, 18, 20, 32),
                children: [
                  _HomeHeader(date: formattedDate),
                  const SizedBox(height: 24),
                  _InventoryHero(
                    value: money.format(provider.totalInvestment),
                    products: provider.productCount,
                    lowStock: lowStock.length,
                    onAction: _showActions,
                  ),
                  const SizedBox(height: 14),
                  _MetricsStrip(
                    productCount: provider.productCount,
                    lowStockCount: lowStock.length,
                    averageProfit: money.format(provider.avgProfit),
                  ),
                  const SizedBox(height: 30),
                  AppSectionHeader(
                    title: 'Necesitan atención',
                    actionLabel: lowStock.isEmpty ? null : 'Ver inventario',
                    onAction: () => DefaultTabController.of(context).animateTo(1),
                  ),
                  const SizedBox(height: 12),
                  if (lowStock.isEmpty)
                    const _HealthyInventoryCard()
                  else
                    ...lowStock.take(4).map(
                          (product) => Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: _LowStockTile(
                              product: product,
                              onTap: () =>
                                  DefaultTabController.of(context).animateTo(1),
                            ),
                          ),
                        ),
                  const SizedBox(height: 22),
                  const AppSectionHeader(title: 'Acceso rápido'),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _ShortcutCard(
                          icon: Icons.inventory_2_outlined,
                          label: 'Productos',
                          caption: 'Gestionar catálogo',
                          onTap: () =>
                              DefaultTabController.of(context).animateTo(1),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _ShortcutCard(
                          icon: Icons.bar_chart_rounded,
                          label: 'Reportes',
                          caption: 'Revisar resultados',
                          onTap: () =>
                              DefaultTabController.of(context).animateTo(4),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  void _showActions() {
    showModalBottomSheet<void>(
      context: context,
      builder: (sheetContext) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Registrar movimiento',
                    style: Theme.of(context).textTheme.headlineSmall),
                const SizedBox(height: 6),
                Text(
                  'Elige la operación que deseas realizar.',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 20),
                _ActionRow(
                  icon: Icons.add_box_outlined,
                  title: 'Agregar un producto',
                  subtitle: 'Crea un nuevo artículo en el inventario',
                  onTap: () => _navigateFromSheet(sheetContext, 1),
                ),
                const SizedBox(height: 10),
                _ActionRow(
                  icon: Icons.move_to_inbox_outlined,
                  title: 'Registrar entrada',
                  subtitle: 'Añade mercancía al stock actual',
                  onTap: () => _navigateFromSheet(sheetContext, 2),
                ),
                const SizedBox(height: 10),
                _ActionRow(
                  icon: Icons.fact_check_outlined,
                  title: 'Realizar cierre',
                  subtitle: 'Cuenta existencias y calcula las ventas',
                  onTap: () => _navigateFromSheet(sheetContext, 3),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _navigateFromSheet(BuildContext sheetContext, int index) {
    Navigator.pop(sheetContext);
    DefaultTabController.of(context).animateTo(index);
  }
}

class _HomeHeader extends StatelessWidget {
  final String date;

  const _HomeHeader({required this.date});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: AppColors.graphite,
            borderRadius: BorderRadius.circular(14),
          ),
          child: const Icon(
            Icons.inventory_2_rounded,
            color: AppColors.amber,
            size: 22,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'FlowStock',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              Text(date, style: Theme.of(context).textTheme.bodySmall),
            ],
          ),
        ),
        Container(
          width: 9,
          height: 9,
          decoration: const BoxDecoration(
            color: AppColors.success,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 7),
        Text(
          'Actualizado',
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
    );
  }
}

class _InventoryHero extends StatelessWidget {
  final String value;
  final int products;
  final int lowStock;
  final VoidCallback onAction;

  const _InventoryHero({
    required this.value,
    required this.products,
    required this.lowStock,
    required this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: AppColors.graphite,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: AppColors.graphite.withAlpha(35),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  'VALOR DEL INVENTARIO',
                  style: TextStyle(
                    color: Colors.white60,
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.25,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withAlpha(18),
                  borderRadius: BorderRadius.circular(11),
                ),
                child: const Icon(
                  Icons.account_balance_wallet_outlined,
                  color: AppColors.amber,
                  size: 20,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              value,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 36,
                height: 1,
                fontWeight: FontWeight.w800,
                letterSpacing: -1.4,
              ),
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              _HeroMeta(value: '$products', label: 'productos'),
              Container(
                width: 1,
                height: 30,
                margin: const EdgeInsets.symmetric(horizontal: 18),
                color: Colors.white12,
              ),
              _HeroMeta(value: '$lowStock', label: 'stock bajo'),
            ],
          ),
          const SizedBox(height: 22),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: onAction,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.amber,
                foregroundColor: AppColors.graphite,
              ),
              icon: const Icon(Icons.add_rounded, size: 20),
              label: const Text('Registrar movimiento'),
            ),
          ),
        ],
      ),
    );
  }
}

class _HeroMeta extends StatelessWidget {
  final String value;
  final String label;

  const _HeroMeta({required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 17,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: const TextStyle(
            color: Colors.white60,
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

class _MetricsStrip extends StatelessWidget {
  final int productCount;
  final int lowStockCount;
  final String averageProfit;

  const _MetricsStrip({
    required this.productCount,
    required this.lowStockCount,
    required this.averageProfit,
  });

  @override
  Widget build(BuildContext context) {
    return AppSurface(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 16),
      child: Row(
        children: [
          Expanded(
            child: _MetricItem(
              value: '$productCount',
              label: 'Productos',
              icon: Icons.inventory_2_outlined,
            ),
          ),
          const SizedBox(height: 44, child: VerticalDivider()),
          Expanded(
            child: _MetricItem(
              value: '$lowStockCount',
              label: 'Bajo stock',
              icon: Icons.error_outline_rounded,
              valueColor:
                  lowStockCount > 0 ? AppColors.danger : AppColors.success,
            ),
          ),
          const SizedBox(height: 44, child: VerticalDivider()),
          Expanded(
            child: _MetricItem(
              value: averageProfit,
              label: 'Prom. diario',
              icon: Icons.trending_up_rounded,
              valueColor: AppColors.success,
            ),
          ),
        ],
      ),
    );
  }
}

class _MetricItem extends StatelessWidget {
  final String value;
  final String label;
  final IconData icon;
  final Color? valueColor;

  const _MetricItem({
    required this.value,
    required this.label,
    required this.icon,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, color: AppColors.textSecondary, size: 18),
        const SizedBox(height: 7),
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            value,
            maxLines: 1,
            style: TextStyle(
              color: valueColor ?? AppColors.textPrimary,
              fontSize: 16,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.2,
            ),
          ),
        ),
        const SizedBox(height: 2),
        Text(label, style: Theme.of(context).textTheme.bodySmall),
      ],
    );
  }
}

class _LowStockTile extends StatelessWidget {
  final Product product;
  final VoidCallback onTap;

  const _LowStockTile({required this.product, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return AppSurface(
      onTap: onTap,
      padding: const EdgeInsets.all(15),
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: AppColors.dangerSoft,
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(
              Icons.inventory_2_outlined,
              color: AppColors.danger,
              size: 21,
            ),
          ),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        product.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                    ),
                    Text(
                      '${product.quantity} uds.',
                      style: const TextStyle(
                        color: AppColors.danger,
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                StockProgress(
                  quantity: product.quantity,
                  minimum: product.minStock,
                ),
                const SizedBox(height: 6),
                Text(
                  'Mínimo recomendado: ${product.minStock}',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          const Icon(
            Icons.chevron_right_rounded,
            color: AppColors.textSecondary,
          ),
        ],
      ),
    );
  }
}

class _HealthyInventoryCard extends StatelessWidget {
  const _HealthyInventoryCard();

  @override
  Widget build(BuildContext context) {
    return AppSurface(
      color: AppColors.successSoft,
      border: Border.all(color: AppColors.success.withAlpha(35)),
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: const BoxDecoration(
              color: AppColors.surface,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.check_rounded,
              color: AppColors.success,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Inventario saludable',
                    style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 2),
                Text(
                  'Todos los productos están por encima del mínimo.',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ShortcutCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String caption;
  final VoidCallback onTap;

  const _ShortcutCard({
    required this.icon,
    required this.label,
    required this.caption,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return AppSurface(
      onTap: onTap,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: AppColors.amberSoft,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: AppColors.graphite, size: 20),
          ),
          const SizedBox(height: 16),
          Text(label, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 2),
          Text(caption, style: Theme.of(context).textTheme.bodySmall),
        ],
      ),
    );
  }
}

class _ActionRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _ActionRow({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return AppSurface(
      onTap: onTap,
      padding: const EdgeInsets.all(14),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppColors.amberSoft,
              borderRadius: BorderRadius.circular(13),
            ),
            child: Icon(icon, color: AppColors.graphite, size: 21),
          ),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: Theme.of(context).textTheme.titleMedium),
                Text(subtitle, style: Theme.of(context).textTheme.bodySmall),
              ],
            ),
          ),
          const Icon(Icons.chevron_right_rounded,
              color: AppColors.textSecondary),
        ],
      ),
    );
  }
}
