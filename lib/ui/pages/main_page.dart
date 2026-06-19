import 'package:flutter/material.dart';
import 'package:cafeteria_flutter/ui/pages/home_page.dart';
import 'package:cafeteria_flutter/ui/pages/products_page.dart';
import 'package:cafeteria_flutter/ui/pages/entries_page.dart';
import 'package:cafeteria_flutter/ui/pages/close_page.dart';
import 'package:cafeteria_flutter/ui/pages/history_page.dart';
import 'package:cafeteria_flutter/ui/pages/curved_bottom_bar.dart';

class MainPage extends StatefulWidget {
  const MainPage({super.key});

  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  static const _pages = <Widget>[
    HomePage(),
    ProductsPage(),
    EntriesPage(),
    ClosePage(),
    HistoryPage(),
  ];

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: _pages.length,
      child: Builder(
        builder: (context) {
          final controller = DefaultTabController.of(context);

          return Scaffold(
            resizeToAvoidBottomInset: true,
            body: TabBarView(
              physics: const NeverScrollableScrollPhysics(),
              children: _pages,
            ),
            bottomNavigationBar: AnimatedBuilder(
              animation: controller,
              builder: (context, _) {
                return CurvedBottomBar(
                  currentIndex: controller.index,
                  onTap: controller.animateTo,
                  items: const [
                    CurvedNavItem(
                      icon: Icons.space_dashboard_rounded,
                      tooltip: 'Inicio',
                    ),
                    CurvedNavItem(
                      icon: Icons.inventory_2_outlined,
                      tooltip: 'Productos',
                    ),
                    CurvedNavItem(
                      icon: Icons.add_rounded,
                      tooltip: 'Entrada',
                    ),
                    CurvedNavItem(
                      icon: Icons.fact_check_outlined,
                      tooltip: 'Cierre',
                    ),
                    CurvedNavItem(
                      icon: Icons.bar_chart_rounded,
                      tooltip: 'Reportes',
                    ),
                  ],
                );
              },
            ),
          );
        },
      ),
    );
  }
}
