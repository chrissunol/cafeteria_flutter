import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cafeteria_flutter/providers/inventory_provider.dart';
import 'package:intl/intl.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = context.read<InventoryProvider>();
      provider.refreshHomeStats();
      provider.fetchProducts();
    });
  }

  @override
  Widget build(BuildContext context) {
    final currencyFormat =
        NumberFormat.currency(symbol: r'$', decimalDigits: 2);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('FlowStock',
            style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: Consumer<InventoryProvider>(
        builder: (context, provider, child) {
          final lowStockProducts =
              provider.products.where((p) => p.quantity <= p.minStock).toList();

          return SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Encabezado Humano
                Row(
                  children: [
                    CircleAvatar(
                      radius: 24,
                      backgroundColor:
                          theme.colorScheme.secondary.withAlpha(30),
                      child: Icon(Icons.person_outline_rounded,
                          color: theme.colorScheme.primary),
                    ),
                    const SizedBox(width: 12),
                    const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '¡Hola de nuevo!',
                          style:
                              TextStyle(fontSize: 14, color: Color(0xFF717680)),
                        ),
                        Text(
                          'Resumen del negocio',
                          style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF181A1F)),
                        ),
                      ],
                    ),
                  ],
                ),

                const SizedBox(height: 24),

                // RESUMEN EN CARDS LIMPIAS
                Row(
                  children: [
                    Expanded(
                      child: _StatCard(
                        title: 'Productos',
                        value: provider.productCount.toString(),
                        icon: Icons.inventory_2_rounded,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _StatCard(
                        title: 'Ganancia Prom.',
                        value: currencyFormat.format(provider.avgProfit),
                        icon: Icons.trending_up_rounded,
                        color: const Color(0xFF16A365),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                _WideStatCard(
                  title: 'Inversión en Inventario',
                  value: currencyFormat.format(provider.totalInvestment),
                  icon: Icons.account_balance_wallet_rounded,
                  color: theme.colorScheme.secondary,
                ),

                const SizedBox(height: 32),

                // ACCESOS RÁPIDOS REALES
                const Text(
                  'Acciones frecuentes',
                  style: TextStyle(
                      color: Color(0xFF181A1F),
                      fontSize: 18,
                      fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                GridView.count(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisCount: 2,
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                  childAspectRatio: 2.2,
                  children: [
                    _QuickAction(
                      label: 'Nuevo Producto',
                      icon: Icons.add_circle_outline_rounded,
                      onTap: () =>
                          DefaultTabController.of(context).animateTo(1),
                    ),
                    _QuickAction(
                      label: 'Entrada',
                      icon: Icons.local_shipping_outlined,
                      onTap: () =>
                          DefaultTabController.of(context).animateTo(2),
                    ),
                    _QuickAction(
                      label: 'Hacer Cierre',
                      icon: Icons.receipt_long_rounded,
                      onTap: () =>
                          DefaultTabController.of(context).animateTo(3),
                    ),
                    _QuickAction(
                      label: 'Ver Reportes',
                      icon: Icons.analytics_outlined,
                      onTap: () =>
                          DefaultTabController.of(context).animateTo(4),
                    ),
                  ],
                ),

                const SizedBox(height: 32),

                // ALERTAS HUMANAS
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Productos por reponer',
                      style: TextStyle(
                        color: Color(0xFF181A1F),
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (lowStockProducts.isNotEmpty)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.error.withAlpha(20),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          'ATENCIÓN',
                          style: TextStyle(
                            color: theme.colorScheme.error,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 16),

                if (lowStockProducts.isEmpty)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(32),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: const Color(0xFFE5E7EB)),
                    ),
                    child: const Column(
                      children: [
                        Icon(Icons.check_circle_rounded,
                            color: Color(0x6616A365), size: 48),
                        SizedBox(height: 12),
                        Text(
                          'Inventario al día',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF181A1F),
                            fontSize: 16,
                          ),
                        ),
                        Text(
                          'No tienes productos bajos en stock.',
                          style:
                              TextStyle(color: Color(0xFF717680), fontSize: 13),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  )
                else
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: lowStockProducts.length,
                    itemBuilder: (context, index) {
                      final p = lowStockProducts[index];
                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        child: ListTile(
                          leading: Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: theme.colorScheme.error.withAlpha(20),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(Icons.warning_amber_rounded,
                                color: theme.colorScheme.error, size: 20),
                          ),
                          title: Text(
                            p.name,
                            style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF181A1F)),
                          ),
                          subtitle: Text(
                            'Quedan: ${p.quantity} | Mínimo: ${p.minStock}',
                            style: const TextStyle(color: Color(0xFF717680)),
                          ),
                          trailing: const Icon(Icons.chevron_right_rounded,
                              color: Color(0xFFE5E7EB)),
                          onTap: () =>
                              DefaultTabController.of(context).animateTo(1),
                        ),
                      );
                    },
                  ),
                const SizedBox(height: 40),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  const _StatCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE5E7EB)),
        boxShadow: [
          BoxShadow(
              color: color.withAlpha(10),
              blurRadius: 10,
              offset: const Offset(0, 4))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 12),
          Text(
            value,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Color(0xFF181A1F),
            ),
          ),
          Text(
            title,
            style: const TextStyle(color: Color(0xFF717680), fontSize: 12),
          ),
        ],
      ),
    );
  }
}

class _WideStatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  const _WideStatCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withAlpha(20),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 28),
          ),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title,
                  style:
                      const TextStyle(color: Color(0xFF717680), fontSize: 13)),
              Text(value,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF181A1F),
                  )),
            ],
          ),
        ],
      ),
    );
  }
}

class _QuickAction extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onTap;

  const _QuickAction({
    required this.label,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFE5E7EB)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: theme.colorScheme.primary, size: 20),
            const SizedBox(width: 8),
            Text(
              label,
              style: const TextStyle(
                  color: Color(0xFF181A1F),
                  fontWeight: FontWeight.bold,
                  fontSize: 13),
            ),
          ],
        ),
      ),
    );
  }
}
