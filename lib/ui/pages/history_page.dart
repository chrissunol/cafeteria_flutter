import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:cafeteria_flutter/models/close.dart';
import 'package:cafeteria_flutter/providers/inventory_provider.dart';
import 'package:cafeteria_flutter/ui/pages/close_detail_page.dart';
import 'package:cafeteria_flutter/ui/theme/app_theme.dart';
import 'package:cafeteria_flutter/ui/widgets/app_ui.dart';

class HistoryPage extends StatefulWidget {
  const HistoryPage({super.key});

  @override
  State<HistoryPage> createState() => _HistoryPageState();
}

class _HistoryPageState extends State<HistoryPage> {
  static const List<int> _periodOptions = [7, 15, 30];
  int _selectedPeriodDays = 7;

  List<Close> _filterClosesByPeriod(List<Close> closes) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final startDate = today.subtract(Duration(days: _selectedPeriodDays - 1));

    return closes.where((close) {
      final parsedDate = DateTime.tryParse(close.date);
      if (parsedDate == null) return false;

      final closeDate = DateTime(
        parsedDate.year,
        parsedDate.month,
        parsedDate.day,
      );

      return !closeDate.isBefore(startDate) && !closeDate.isAfter(today);
    }).toList();
  }
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<InventoryProvider>().fetchCloses();
    });
  }

  @override
  Widget build(BuildContext context) {
    final money = NumberFormat.currency(symbol: r'$', decimalDigits: 2);

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Consumer<InventoryProvider>(
          builder: (context, provider, _) {
            if (provider.closes.isEmpty) {
              return Column(
                children: [
                  const AppPageHeader(
                    title: 'Reportes',
                    subtitle: 'Resultados de tus cierres diarios',
                  ),
                  Expanded(
                    child: AppEmptyState(
                      icon: Icons.bar_chart_rounded,
                      title: 'Todavía no hay reportes',
                      message:
                          'Cuando realices un cierre diario podrás consultar ventas, ganancias y unidades vendidas.',
                      actionLabel: 'Hacer primer cierre',
                      onAction: () =>
                          DefaultTabController.of(context).animateTo(3),
                    ),
                  ),
                ],
              );
            }

            final filteredCloses = _filterClosesByPeriod(provider.closes);
            final profit = filteredCloses.fold<double>(
              0,
              (sum, close) => sum + close.totalProfit,
            );
            final revenue = filteredCloses.fold<double>(
              0,
              (sum, close) => sum + close.totalRevenue,
            );
            final units = filteredCloses.fold<int>(
              0,
              (sum, close) => sum + close.totalSoldUnits,
            );

            return RefreshIndicator(
              onRefresh: provider.fetchCloses,
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.only(bottom: 30),
                children: [
                  const AppPageHeader(
                    title: 'Reportes',
                    subtitle: 'Resultados de tus cierres diarios',
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: _ReportHero(
                      profit: money.format(profit),
                      revenue: money.format(revenue),
                      closes: filteredCloses.length,
                      units: units,
                      selectedPeriodDays: _selectedPeriodDays,
                      periodOptions: _periodOptions,
                      onPeriodChanged: (days) {
                        setState(() => _selectedPeriodDays = days);
                      },
                    ),
                  ),
                  const SizedBox(height: 28),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 20),
                    child: AppSectionHeader(title: 'Historial de cierres'),
                  ),
                  const SizedBox(height: 12),
                  ...provider.closes.map(
                    (close) => Padding(
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 10),
                      child: _CloseReportCard(
                        close: close,
                        profit: money.format(close.totalProfit),
                        revenue: money.format(close.totalRevenue),
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => CloseDetailPage(date: close.date),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

class _ReportHero extends StatelessWidget {
  final String profit;
  final String revenue;
  final int closes;
  final int units;
  final int selectedPeriodDays;
  final List<int> periodOptions;
  final ValueChanged<int> onPeriodChanged;

  const _ReportHero({
    required this.profit,
    required this.revenue,
    required this.closes,
    required this.units,
    required this.selectedPeriodDays,
    required this.periodOptions,
    required this.onPeriodChanged,
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
            color: AppColors.graphite.withAlpha(32),
            blurRadius: 22,
            offset: const Offset(0, 11),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Expanded(
                child: Text(
                  'GANANCIA ACUMULADA',
                  style: TextStyle(
                    color: Colors.white60,
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.2,
                  ),
                ),
              ),
              Icon(
                Icons.trending_up_rounded,
                color: AppColors.amber,
                size: 23,
              ),
            ],
          ),
          const SizedBox(height: 14),
          _PeriodSelector(
            options: periodOptions,
            selectedDays: selectedPeriodDays,
            onChanged: onPeriodChanged,
          ),
          const SizedBox(height: 18),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              profit,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 36,
                height: 1,
                fontWeight: FontWeight.w800,
                letterSpacing: -1.3,
              ),
            ),
          ),
          const SizedBox(height: 22),
          Container(height: 1, color: Colors.white12),
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(
                child: _ReportMetric(label: 'Ventas', value: revenue),
              ),
              Expanded(
                child: _ReportMetric(label: 'Cierres', value: '$closes'),
              ),
              Expanded(
                child: _ReportMetric(label: 'Unidades', value: '$units'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _PeriodSelector extends StatelessWidget {
  final List<int> options;
  final int selectedDays;
  final ValueChanged<int> onChanged;

  const _PeriodSelector({
    required this.options,
    required this.selectedDays,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.white.withAlpha(18),
        borderRadius: BorderRadius.circular(13),
        border: Border.all(color: Colors.white.withAlpha(18)),
      ),
      child: Row(
        children: options.map((days) {
          final isSelected = days == selectedDays;

          return Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 2),
              child: Material(
                color: isSelected ? AppColors.amber : Colors.transparent,
                borderRadius: BorderRadius.circular(10),
                child: InkWell(
                  onTap: () => onChanged(days),
                  borderRadius: BorderRadius.circular(10),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    child: Text(
                      '$days días',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: isSelected
                            ? AppColors.graphite
                            : Colors.white70,
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _ReportMetric extends StatelessWidget {
  final String label;
  final String value;

  const _ReportMetric({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.centerLeft,
          child: Text(
            value,
            maxLines: 1,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 15,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: const TextStyle(color: Colors.white54, fontSize: 11),
        ),
      ],
    );
  }
}

class _CloseReportCard extends StatelessWidget {
  final Close close;
  final String profit;
  final String revenue;
  final VoidCallback onTap;

  const _CloseReportCard({
    required this.close,
    required this.profit,
    required this.revenue,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final date = DateTime.parse(close.date);
    final day = DateFormat('d').format(date);
    final month = DateFormat('MMM', 'es').format(date).toUpperCase();
    final weekDay = DateFormat('EEEE', 'es').format(date);
    final weekDayLabel = weekDay.isEmpty
        ? weekDay
        : '${weekDay[0].toUpperCase()}${weekDay.substring(1)}';

    return AppSurface(
      onTap: onTap,
      padding: const EdgeInsets.all(15),
      child: Row(
        children: [
          Container(
            width: 54,
            height: 58,
            decoration: BoxDecoration(
              color: AppColors.amberSoft,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  day,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 20,
                    height: 1,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  month,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(weekDayLabel,
                    style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 3),
                Text(
                  '${close.totalSoldUnits} unidades · Ventas $revenue',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
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
          const SizedBox(width: 4),
          const Icon(
            Icons.chevron_right_rounded,
            color: AppColors.textSecondary,
          ),
        ],
      ),
    );
  }
}
