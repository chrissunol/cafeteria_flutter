import 'package:cafeteria_flutter/data/backup_service.dart';
import 'package:cafeteria_flutter/providers/inventory_provider.dart';
import 'package:cafeteria_flutter/ui/theme/app_theme.dart';
import 'package:cafeteria_flutter/ui/widgets/app_ui.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

class DataManagementPage extends StatefulWidget {
  const DataManagementPage({super.key});

  @override
  State<DataManagementPage> createState() => _DataManagementPageState();
}

class _DataManagementPageState extends State<DataManagementPage> {
  final BackupService _backupService = BackupService();
  bool _busy = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Datos y respaldo')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
        children: [
          const _BackupHero(),
          const SizedBox(height: 26),
          const AppSectionHeader(title: 'Protege tu información'),
          const SizedBox(height: 12),
          _DataAction(
            icon: Icons.cloud_upload_outlined,
            title: 'Crear respaldo',
            description:
                'Guarda productos, entradas, cierres y movimientos en un archivo JSON.',
            buttonLabel: 'Exportar archivo',
            onPressed: _busy ? null : _export,
          ),
          const SizedBox(height: 12),
          _DataAction(
            icon: Icons.restore_rounded,
            title: 'Restaurar respaldo',
            description:
                'Reemplaza los datos actuales con el contenido de un respaldo de FlowStock.',
            buttonLabel: 'Elegir archivo',
            warning: true,
            onPressed: _busy ? null : _restore,
          ),
          const SizedBox(height: 12),
          _DataAction(
            icon: Icons.inventory_2_outlined,
            title: 'Productos archivados',
            description:
                'Consulta artículos retirados del inventario y restáuralos cuando vuelvan a utilizarse.',
            buttonLabel: 'Ver archivados',
            onPressed: _busy ? null : _showArchivedProducts,
          ),
          if (_busy) ...[
            const SizedBox(height: 20),
            const LinearProgressIndicator(),
          ],
        ],
      ),
    );
  }

  Future<void> _export() async {
    setState(() => _busy = true);
    try {
      final bytes = await _backupService.createBackup();
      final date = DateFormat('yyyy-MM-dd_HHmm').format(DateTime.now());
      final path = await FilePicker.saveFile(
        dialogTitle: 'Guardar respaldo de FlowStock',
        fileName: 'flowstock_$date.json',
        type: FileType.custom,
        allowedExtensions: const ['json'],
        bytes: bytes,
      );
      if (!mounted || path == null) return;
      _showMessage('Respaldo creado correctamente.', AppColors.success);
    } catch (error) {
      if (mounted) {
        _showMessage('No se pudo crear el respaldo: $error', AppColors.danger);
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _restore() async {
    final selection = await FilePicker.pickFiles(
      dialogTitle: 'Seleccionar respaldo de FlowStock',
      type: FileType.custom,
      allowedExtensions: const ['json'],
    );
    if (!mounted || selection.isEmpty) return;

    final bytes = await selection.single.readAsBytes();
    if (!mounted) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        icon: const Icon(Icons.warning_amber_rounded, color: AppColors.warning),
        title: const Text('¿Restaurar este respaldo?'),
        content: const Text(
          'Los datos actuales serán reemplazados. Crea primero un respaldo si deseas conservarlos.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Restaurar'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    setState(() => _busy = true);
    try {
      await _backupService.restoreBackup(bytes);
      if (!mounted) return;
      final provider = context.read<InventoryProvider>();
      await Future.wait([
        provider.fetchProducts(),
        provider.fetchEntries(),
        provider.fetchCloses(),
        provider.refreshHomeStats(),
      ]);
      if (mounted) {
        _showMessage('Datos restaurados correctamente.', AppColors.success);
      }
    } catch (error) {
      if (mounted) {
        _showMessage('No se pudo restaurar: $error', AppColors.danger);
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _showArchivedProducts() async {
    setState(() => _busy = true);
    final provider = context.read<InventoryProvider>();
    try {
      final products = await provider.getArchivedProducts();
      if (!mounted) return;
      if (products.isEmpty) {
        _showMessage('No hay productos archivados.', AppColors.success);
        return;
      }

      await showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        builder: (sheetContext) => FractionallySizedBox(
          heightFactor: 0.72,
          child: SafeArea(
            top: false,
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 4, 20, 12),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Productos archivados',
                          style: Theme.of(sheetContext).textTheme.headlineSmall,
                        ),
                      ),
                      AppStatusPill(
                        label: '${products.length}',
                        color: AppColors.textPrimary,
                        backgroundColor: AppColors.amberSoft,
                      ),
                    ],
                  ),
                ),
                const Divider(),
                Expanded(
                  child: ListView.separated(
                    padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
                    itemCount: products.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (_, index) {
                      final product = products[index];
                      return AppSurface(
                        padding: const EdgeInsets.fromLTRB(16, 12, 10, 12),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    product.name,
                                    style: Theme.of(sheetContext)
                                        .textTheme
                                        .titleMedium,
                                  ),
                                  const SizedBox(height: 3),
                                  Text(
                                    '${product.quantity} unidades guardadas',
                                    style: Theme.of(sheetContext)
                                        .textTheme
                                        .bodySmall,
                                  ),
                                ],
                              ),
                            ),
                            TextButton.icon(
                              onPressed: () async {
                                await provider.restoreProduct(product.id!);
                                if (!sheetContext.mounted) return;
                                Navigator.pop(sheetContext);
                                if (mounted) {
                                  _showMessage(
                                    '${product.name} volvió al inventario.',
                                    AppColors.success,
                                  );
                                }
                              },
                              icon: const Icon(Icons.restore_rounded, size: 18),
                              label: const Text('Restaurar'),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    } catch (error) {
      if (mounted) {
        _showMessage(
            'No se pudieron cargar los archivados: $error', AppColors.danger);
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _showMessage(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: color),
    );
  }
}

class _BackupHero extends StatelessWidget {
  const _BackupHero();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: AppColors.graphite,
        borderRadius: BorderRadius.circular(24),
      ),
      child: const Row(
        children: [
          Icon(Icons.shield_outlined, color: AppColors.amber, size: 36),
          SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Tus datos son tuyos',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 19,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                SizedBox(height: 5),
                Text(
                  'FlowStock funciona sin conexión. Guarda un respaldo periódicamente.',
                  style: TextStyle(color: Colors.white60, height: 1.4),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DataAction extends StatelessWidget {
  const _DataAction({
    required this.icon,
    required this.title,
    required this.description,
    required this.buttonLabel,
    required this.onPressed,
    this.warning = false,
  });

  final IconData icon;
  final String title;
  final String description;
  final String buttonLabel;
  final VoidCallback? onPressed;
  final bool warning;

  @override
  Widget build(BuildContext context) {
    return AppSurface(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: warning ? AppColors.warningSoft : AppColors.amberSoft,
                  borderRadius: BorderRadius.circular(13),
                ),
                child: Icon(icon,
                    color: warning ? AppColors.warning : AppColors.graphite),
              ),
              const SizedBox(width: 13),
              Expanded(
                  child: Text(title,
                      style: Theme.of(context).textTheme.titleMedium)),
            ],
          ),
          const SizedBox(height: 12),
          Text(description, style: Theme.of(context).textTheme.bodyMedium),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: warning
                ? OutlinedButton(onPressed: onPressed, child: Text(buttonLabel))
                : ElevatedButton(
                    onPressed: onPressed, child: Text(buttonLabel)),
          ),
        ],
      ),
    );
  }
}
