import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:cafeteria_flutter/providers/inventory_provider.dart';
import 'package:cafeteria_flutter/ui/theme/app_theme.dart';
import 'package:cafeteria_flutter/ui/widgets/app_ui.dart';

class ClosePage extends StatefulWidget {
  const ClosePage({super.key});

  @override
  State<ClosePage> createState() => _ClosePageState();
}

class _ClosePageState extends State<ClosePage> {
  final Map<int, int> _finals = {};
  final TextEditingController _searchCtrl = TextEditingController();
  final String _todayStr = DateFormat('yyyy-MM-dd').format(DateTime.now());
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
    final friendlyDate = DateFormat('d MMMM yyyy', 'es').format(DateTime.now());

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            const AppPageHeader(
              title: 'Cierre diario',
              subtitle: 'Cuenta lo que quedó al finalizar el día',
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
              child: _CloseGuide(
                date: friendlyDate,
                counted: _finals.length,
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 14),
              child: AppSearchField(
                controller: _searchCtrl,
                hintText: 'Buscar producto para contar...',
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
                      icon: Icons.fact_check_outlined,
                      title: _searchQuery.isEmpty
                          ? 'No hay productos para cerrar'
                          : 'No encontramos ese producto',
                      message: _searchQuery.isEmpty
                          ? 'Agrega productos al inventario antes de realizar un cierre diario.'
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
                      final selected = _finals.containsKey(product.id);

                      return _CloseProductCard(
                        key: ValueKey('${product.id}-$_formVersion'),
                        name: product.name,
                        expected: product.quantity,
                        selected: selected,
                        finalQuantity: product.id == null
                            ? null
                            : _finals[product.id!],
                        onChanged: (value) {
                          if (product.id == null) return;
                          setState(() {
                            if (value == null) {
                              _finals.remove(product.id);
                            } else {
                              _finals[product.id!] = value;
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
        label: 'Realizar cierre diario',
        icon: Icons.check_circle_outline_rounded,
        onPressed: _doClose,
        helperText: _finals.isEmpty
            ? 'Los productos sin contar conservarán su cantidad actual.'
            : '${_finals.length} productos contados manualmente',
      ),
    );
  }

  Future<void> _doClose() async {
    FocusScope.of(context).unfocus();
    final provider = context.read<InventoryProvider>();
    final exists = await provider.checkCloseExists(_todayStr);
    if (!mounted) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(exists ? 'Actualizar cierre' : 'Confirmar cierre'),
        content: Text(
          exists
              ? 'Ya existe un cierre para hoy. Los datos ingresados reemplazarán el conteo anterior.'
              : 'Las ventas se calcularán comparando el stock esperado con las cantidades que contaste.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: Text(exists ? 'Actualizar' : 'Hacer cierre'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    try {
      if (exists) {
        await provider.updateClose(_todayStr, Map.of(_finals));
      } else {
        await provider.generateClose(_todayStr, Map.of(_finals));
      }

      if (!mounted) return;
      setState(() {
        _finals.clear();
        _searchCtrl.clear();
        _searchQuery = '';
        _formVersion++;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            exists
                ? 'Cierre actualizado correctamente.'
                : 'Cierre completado correctamente.',
          ),
          backgroundColor: AppColors.success,
        ),
      );
      DefaultTabController.of(context).animateTo(4);
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('No se pudo completar el cierre: $error'),
          backgroundColor: AppColors.danger,
        ),
      );
    }
  }
}

class _CloseGuide extends StatelessWidget {
  final String date;
  final int counted;

  const _CloseGuide({required this.date, required this.counted});

  @override
  Widget build(BuildContext context) {
    return AppSurface(
      color: AppColors.graphite,
      border: const Border(),
      padding: const EdgeInsets.all(17),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: Colors.white.withAlpha(18),
              borderRadius: BorderRadius.circular(13),
            ),
            child: const Icon(
              Icons.calendar_today_outlined,
              color: AppColors.amber,
              size: 20,
            ),
          ),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  date,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  counted == 0
                      ? 'Escribe únicamente las cantidades que verificaste.'
                      : '$counted productos contados',
                  style: const TextStyle(
                    color: Colors.white60,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          AppStatusPill(
            label: counted == 0 ? 'Pendiente' : 'En progreso',
            color: AppColors.graphite,
            backgroundColor: AppColors.amber,
          ),
        ],
      ),
    );
  }
}

class _CloseProductCard extends StatelessWidget {
  final String name;
  final int expected;
  final bool selected;
  final int? finalQuantity;
  final ValueChanged<int?> onChanged;

  const _CloseProductCard({
    super.key,
    required this.name,
    required this.expected,
    required this.selected,
    required this.finalQuantity,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final sold = finalQuantity == null
        ? 0
        : (expected - finalQuantity!).clamp(0, expected);

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
              selected ? Icons.fact_check_rounded : Icons.inventory_2_outlined,
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
                  selected
                      ? 'Esperado: $expected · Vendido: $sold'
                      : 'Cantidad esperada: $expected',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          SizedBox(
            width: 84,
            child: TextField(
              keyboardType: TextInputType.number,
              textAlign: TextAlign.center,
              onChanged: (value) {
                final clean = value.trim();
                onChanged(clean.isEmpty ? null : int.tryParse(clean));
              },
              decoration: InputDecoration(
                hintText: '$expected',
                labelText: 'Quedan',
                isDense: true,
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
