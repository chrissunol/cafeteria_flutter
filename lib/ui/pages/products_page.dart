import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:cafeteria_flutter/models/product.dart';
import 'package:cafeteria_flutter/providers/inventory_provider.dart';
import 'package:cafeteria_flutter/ui/theme/app_theme.dart';
import 'package:cafeteria_flutter/ui/widgets/app_ui.dart';

class ProductsPage extends StatefulWidget {
  const ProductsPage({super.key});

  @override
  State<ProductsPage> createState() => _ProductsPageState();
}

class _ProductsPageState extends State<ProductsPage> {
  final TextEditingController _searchCtrl = TextEditingController();
  String _searchQuery = '';

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
    final money = NumberFormat.currency(symbol: r'$', decimalDigits: 2);

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            AppPageHeader(
              title: 'Productos',
              subtitle: 'Catálogo y existencias',
              trailing: AppIconButton(
                icon: Icons.add_rounded,
                tooltip: 'Agregar producto',
                backgroundColor: AppColors.amber,
                onPressed: () => _showProductSheet(context, null),
              ),
            ),
            Consumer<InventoryProvider>(
              builder: (context, provider, _) {
                final lowStock = provider.products
                    .where((product) => product.quantity <= product.minStock)
                    .length;
                final inventoryValue = provider.products.fold<double>(
                  0,
                  (sum, product) =>
                      sum + (product.costPrice * product.quantity),
                );

                return Padding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 14),
                  child: _CatalogSummary(
                    products: provider.products.length,
                    lowStock: lowStock,
                    value: money.format(inventoryValue),
                  ),
                );
              },
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 14),
              child: AppSearchField(
                controller: _searchCtrl,
                hintText: 'Buscar por nombre...',
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
                      icon: _searchQuery.isEmpty
                          ? Icons.inventory_2_outlined
                          : Icons.search_off_rounded,
                      title: _searchQuery.isEmpty
                          ? 'Tu catálogo está vacío'
                          : 'No encontramos resultados',
                      message: _searchQuery.isEmpty
                          ? 'Agrega el primer producto para comenzar a controlar costos, precios y existencias.'
                          : 'Revisa el nombre o prueba con una búsqueda diferente.',
                      actionLabel:
                          _searchQuery.isEmpty ? 'Agregar producto' : null,
                      onAction: _searchQuery.isEmpty
                          ? () => _showProductSheet(context, null)
                          : null,
                    );
                  }

                  return ListView.separated(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 30),
                    itemCount: products.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (context, index) {
                      final product = products[index];
                      return _ProductCard(
                        product: product,
                        salePrice: money.format(product.salePrice),
                        onEdit: () => _showProductSheet(context, product),
                        onDelete: () => _confirmDelete(context, product),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showProductSheet(BuildContext context, Product? product) async {
    final nameCtrl = TextEditingController(text: product?.name ?? '');
    final costCtrl = TextEditingController(
      text: product == null ? '' : product.costPrice.toStringAsFixed(2),
    );
    final saleCtrl = TextEditingController(
      text: product == null ? '' : product.salePrice.toStringAsFixed(2),
    );
    final qtyCtrl = TextEditingController(
      text: product?.quantity.toString() ?? '0',
    );
    final minCtrl = TextEditingController(
      text: product?.minStock.toString() ?? '5',
    );

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (sheetContext) {
        return Padding(
          padding: EdgeInsets.fromLTRB(
            20,
            4,
            20,
            20 + MediaQuery.viewInsetsOf(sheetContext).bottom,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  product == null ? 'Nuevo producto' : 'Editar producto',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 5),
                Text(
                  product == null
                      ? 'Registra la información básica del artículo.'
                      : 'Actualiza los datos del artículo seleccionado.',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 22),
                _FormField(
                  controller: nameCtrl,
                  label: 'Nombre del producto',
                  icon: Icons.inventory_2_outlined,
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _FormField(
                        controller: costCtrl,
                        label: 'Costo',
                        icon: Icons.payments_outlined,
                        decimal: true,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _FormField(
                        controller: saleCtrl,
                        label: 'Venta',
                        icon: Icons.sell_outlined,
                        decimal: true,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _FormField(
                        controller: qtyCtrl,
                        label: 'Stock actual',
                        icon: Icons.numbers_rounded,
                        integer: true,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _FormField(
                        controller: minCtrl,
                        label: 'Stock mínimo',
                        icon: Icons.notifications_none_rounded,
                        integer: true,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 22),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () async {
                      final name = nameCtrl.text.trim();
                      final cost = double.tryParse(costCtrl.text.trim());
                      final sale = double.tryParse(saleCtrl.text.trim());
                      final quantity = int.tryParse(qtyCtrl.text.trim());
                      final minimum = int.tryParse(minCtrl.text.trim());

                      if (name.isEmpty) {
                        _showError(context, 'Escribe el nombre del producto.');
                        return;
                      }
                      if (cost == null || sale == null || cost < 0 || sale < 0) {
                        _showError(context, 'Revisa los precios ingresados.');
                        return;
                      }
                      if (quantity == null || minimum == null ||
                          quantity < 0 || minimum < 0) {
                        _showError(context, 'Revisa las cantidades ingresadas.');
                        return;
                      }

                      final provider = context.read<InventoryProvider>();
                      final duplicate = provider.products.any(
                        (item) =>
                            item.name.toLowerCase() == name.toLowerCase() &&
                            item.id != product?.id,
                      );
                      if (duplicate) {
                        _showError(context, 'Ya existe un producto con ese nombre.');
                        return;
                      }

                      await provider.upsertProduct(
                        Product(
                          id: product?.id,
                          name: name,
                          costPrice: cost,
                          salePrice: sale,
                          quantity: quantity,
                          minStock: minimum,
                          updatedAt: DateTime.now().millisecondsSinceEpoch,
                        ),
                      );

                      if (!mounted) return;
                      Navigator.pop(sheetContext);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            product == null
                                ? 'Producto agregado correctamente.'
                                : 'Producto actualizado correctamente.',
                          ),
                        ),
                      );
                    },
                    icon: const Icon(Icons.check_rounded),
                    label: Text(product == null
                        ? 'Guardar producto'
                        : 'Guardar cambios'),
                  ),
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),
        );
      },
    );

    nameCtrl.dispose();
    costCtrl.dispose();
    saleCtrl.dispose();
    qtyCtrl.dispose();
    minCtrl.dispose();
  }

  void _showError(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.danger,
      ),
    );
  }

  Future<void> _confirmDelete(BuildContext context, Product product) async {
    if (product.id == null) return;
    final provider = context.read<InventoryProvider>();
    final hasHistory = await provider.hasHistory(product.id!);
    if (!mounted) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Eliminar producto'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('¿Deseas eliminar “${product.name}”?'),
              if (hasHistory) ...[
                const SizedBox(height: 14),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.dangerSoft,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.warning_amber_rounded,
                          color: AppColors.danger, size: 19),
                      SizedBox(width: 9),
                      Expanded(
                        child: Text(
                          'Este producto tiene historial y su eliminación puede afectar reportes anteriores.',
                          style: TextStyle(
                            color: AppColors.danger,
                            fontSize: 12,
                            height: 1.4,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
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
        );
      },
    );

    if (confirmed == true) {
      await provider.deleteProduct(product.id!);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Producto eliminado.')),
      );
    }
  }
}

class _CatalogSummary extends StatelessWidget {
  final int products;
  final int lowStock;
  final String value;

  const _CatalogSummary({
    required this.products,
    required this.lowStock,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return AppSurface(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          Expanded(
            child: _SummaryValue(label: 'Productos', value: '$products'),
          ),
          const SizedBox(height: 35, child: VerticalDivider()),
          Expanded(
            child: _SummaryValue(
              label: 'Stock bajo',
              value: '$lowStock',
              color: lowStock > 0 ? AppColors.danger : AppColors.success,
            ),
          ),
          const SizedBox(height: 35, child: VerticalDivider()),
          Expanded(
            child: _SummaryValue(label: 'Valor', value: value),
          ),
        ],
      ),
    );
  }
}

class _SummaryValue extends StatelessWidget {
  final String label;
  final String value;
  final Color? color;

  const _SummaryValue({required this.label, required this.value, this.color});

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
              color: color ?? AppColors.textPrimary,
              fontSize: 15,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        const SizedBox(height: 2),
        Text(label, style: Theme.of(context).textTheme.bodySmall),
      ],
    );
  }
}

class _ProductCard extends StatelessWidget {
  final Product product;
  final String salePrice;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _ProductCard({
    required this.product,
    required this.salePrice,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final lowStock = product.quantity <= product.minStock;

    return AppSurface(
      padding: const EdgeInsets.all(15),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: lowStock ? AppColors.dangerSoft : AppColors.amberSoft,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(
              Icons.inventory_2_outlined,
              color: lowStock ? AppColors.danger : AppColors.graphite,
              size: 22,
            ),
          ),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        product.name,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                    ),
                    const SizedBox(width: 8),
                    PopupMenuButton<String>(
                      padding: EdgeInsets.zero,
                      icon: const Icon(
                        Icons.more_horiz_rounded,
                        color: AppColors.textSecondary,
                      ),
                      onSelected: (value) {
                        if (value == 'edit') onEdit();
                        if (value == 'delete') onDelete();
                      },
                      itemBuilder: (_) => const [
                        PopupMenuItem(
                          value: 'edit',
                          child: Row(
                            children: [
                              Icon(Icons.edit_outlined, size: 19),
                              SizedBox(width: 10),
                              Text('Editar'),
                            ],
                          ),
                        ),
                        PopupMenuItem(
                          value: 'delete',
                          child: Row(
                            children: [
                              Icon(Icons.delete_outline_rounded,
                                  size: 19, color: AppColors.danger),
                              SizedBox(width: 10),
                              Text('Eliminar',
                                  style: TextStyle(color: AppColors.danger)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                Text(
                  'Precio de venta: $salePrice',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    AppStatusPill(
                      label: lowStock
                          ? 'Stock bajo · ${product.quantity}'
                          : '${product.quantity} unidades',
                      color: lowStock ? AppColors.danger : AppColors.success,
                      backgroundColor:
                          lowStock ? AppColors.dangerSoft : AppColors.successSoft,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: StockProgress(
                        quantity: product.quantity,
                        minimum: product.minStock,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _FormField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final IconData icon;
  final bool decimal;
  final bool integer;

  const _FormField({
    required this.controller,
    required this.label,
    required this.icon,
    this.decimal = false,
    this.integer = false,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      keyboardType: decimal
          ? const TextInputType.numberWithOptions(decimal: true)
          : integer
              ? TextInputType.number
              : TextInputType.text,
      textCapitalization:
          integer || decimal ? TextCapitalization.none : TextCapitalization.sentences,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, size: 19),
      ),
    );
  }
}
