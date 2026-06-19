import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cafeteria_flutter/providers/inventory_provider.dart';
import 'package:cafeteria_flutter/ui/pages/entry_history_page.dart';
import 'package:cafeteria_flutter/ui/theme/app_theme.dart';
import 'package:cafeteria_flutter/ui/widgets/app_ui.dart';

class EntriesPage extends StatefulWidget {
  const EntriesPage({super.key});

  @override
  State<EntriesPage> createState() => _EntriesPageState();
}

class _EntriesPageState extends State<EntriesPage> {
  final Map<int, int> _deltas = {};
  final TextEditingController _searchCtrl = TextEditingController();
  String _searchQuery = '';
  int _formVersion = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<InventoryProvider>().fetchProducts();
    });
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final totalUnits = _deltas.values.fold<int>(0, (sum, value) => sum + value);

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            AppPageHeader(
              title: 'Entrada de stock',
              subtitle: 'Agrega mercancía recibida',
              trailing: AppIconButton(
                icon: Icons.history_rounded,
                tooltip: 'Historial de entradas',
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const EntryHistoryPage(),
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
              child: _EntrySummary(
                selectedProducts: _deltas.length,
                totalUnits: totalUnits,
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 14),
              child: AppSearchField(
                controller: _searchCtrl,
                hintText: 'Buscar producto para abastecer...',
                onChanged: (value) => setState(
                  () => _searchQuery = value.trim().toLowerCase(),
                ),
                onClear: () {
                  _searchCtrl.clear();
                  setState(() => _searchQuery = '');
                },
              ),
            ),
            Expanded(
              child: Consumer<InventoryProvider>(
                builder: (context, provider, _) {
                  final products = provider.products
                      .where((product) => product.name
                          .toLowerCase()
                          .contains(_searchQuery))
                      .toList()
                    ..sort((a, b) => a.name.compareTo(b.name));

                  if (products.isEmpty) {
                    return AppEmptyState(
                      icon: Icons.move_to_inbox_outlined,
                      title: _searchQuery.isEmpty
                          ? 'No hay productos disponibles'
                          : 'No encontramos ese producto',
                      message: _searchQuery.isEmpty
                          ? 'Primero agrega productos al catálogo para poder registrar entradas.'
                          : 'Prueba buscando con otro nombre.',
                      actionLabel:
                          _searchQuery.isEmpty ? 'Ir a productos' : null,
                      onAction: _searchQuery.isEmpty
                          ? () => DefaultTabController.of(context).animateTo(1)
                          : null,
                    );
                  }

                  return ListView.separated(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 26),
                    itemCount: products.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (context, index) {
                      final product = products[index];
                      final selected = _deltas.containsKey(product.id);

                      return _EntryProductCard(
                        key: ValueKey('${product.id}-$_formVersion'),
                        name: product.name,
                        stock: product.quantity,
                        selected: selected,
                        onChanged: (quantity) {
                          if (product.id == null) return;
                          setState(() {
                            if (quantity > 0) {
                              _deltas[product.id!] = quantity;
                            } else {
                              _deltas.remove(product.id);
                            }
                          });
                        },
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: AppBottomAction(
        label: 'Registrar entrada',
        icon: Icons.move_to_inbox_rounded,
        onPressed: _saveEntries,
        helperText: _deltas.isEmpty
            ? 'Escribe una cantidad en al menos un producto.'
            : '${_deltas.length} productos · $totalUnits unidades por agregar',
      ),
    );
  }

  Future<void> _saveEntries() async {
    _deltas.removeWhere((_, value) => value <= 0);

    if (_deltas.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Ingresa una cantidad mayor que cero.'),
          backgroundColor: AppColors.warning,
        ),
      );
      return;
    }

    FocusScope.of(context).unfocus();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Confirmar entrada'),
        content: Text(
          'Se actualizará el stock de ${_deltas.length} productos. ¿Deseas continuar?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Confirmar'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    try {
      await context.read<InventoryProvider>().addEntries(Map.of(_deltas));
      if (!mounted) return;
      setState(() {
        _deltas.clear();
        _searchCtrl.clear();
        _searchQuery = '';
        _formVersion++;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Entrada registrada correctamente.'),
          backgroundColor: AppColors.success,
        ),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('No se pudo registrar la entrada: $error'),
          backgroundColor: AppColors.danger,
        ),
      );
    }
  }
}

class _EntrySummary extends StatelessWidget {
  final int selectedProducts;
  final int totalUnits;

  const _EntrySummary({
    required this.selectedProducts,
    required this.totalUnits,
  });

  @override
  Widget build(BuildContext context) {
    return AppSurface(
      color: AppColors.amberSoft,
      border: Border.all(color: AppColors.amber.withAlpha(70)),
      padding: const EdgeInsets.all(15),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: AppColors.amber,
              borderRadius: BorderRadius.circular(13),
            ),
            child: const Icon(
              Icons.local_shipping_outlined,
              color: AppColors.graphite,
              size: 21,
            ),
          ),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  selectedProducts == 0
                      ? 'Selecciona los productos recibidos'
                      : '$selectedProducts productos seleccionados',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                Text(
                  totalUnits == 0
                      ? 'La cantidad se sumará al stock actual.'
                      : '$totalUnits unidades en esta entrada',
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

class _EntryProductCard extends StatelessWidget {
  final String name;
  final int stock;
  final bool selected;
  final ValueChanged<int> onChanged;

  const _EntryProductCard({
    super.key,
    required this.name,
    required this.stock,
    required this.selected,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return AppSurface(
      border: Border.all(
        color: selected ? AppColors.amber : AppColors.border,
        width: selected ? 1.4 : 1,
      ),
      padding: const EdgeInsets.all(15),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: selected ? AppColors.amberSoft : AppColors.background,
              borderRadius: BorderRadius.circular(13),
            ),
            child: Icon(
              selected ? Icons.add_box_rounded : Icons.inventory_2_outlined,
              color: selected ? AppColors.graphite : AppColors.textSecondary,
              size: 21,
            ),
          ),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 3),
                Text(
                  'Stock actual: $stock',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          SizedBox(
            width: 82,
            child: TextField(
              keyboardType: TextInputType.number,
              textAlign: TextAlign.center,
              onChanged: (value) => onChanged(int.tryParse(value) ?? 0),
              decoration: const InputDecoration(
                hintText: '0',
                labelText: 'Agregar',
                isDense: true,
                contentPadding:
                    EdgeInsets.symmetric(horizontal: 10, vertical: 12),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
