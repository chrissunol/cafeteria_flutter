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
  final List<Widget> _pages = [
    const HomePage(),
    const ProductsPage(),
    const EntriesPage(),
    const ClosePage(),
    const HistoryPage(),
  ];

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: _pages.length,
      child: Builder(builder: (context) {
        final tabController = DefaultTabController.of(context);

        return Scaffold(
          body: TabBarView(
            physics: const NeverScrollableScrollPhysics(),
            children: _pages,
          ),
          bottomNavigationBar: AnimatedBuilder(
            animation: tabController,
            builder: (context, _) {
              return CurvedBottomBar(
                currentIndex: tabController.index,
                onTap: (index) {
                  tabController.animateTo(index);
                },
                items: const [
                  CurvedNavItem(
                    icon: Icons.home_rounded,
                    tooltip: 'Inicio',
                  ),
                  CurvedNavItem(
                    icon: Icons.coffee_rounded,
                    tooltip: 'Stock',
                  ),
                  CurvedNavItem(
                    icon: Icons.add_circle_rounded,
                    tooltip: 'Entradas',
                  ),
                  CurvedNavItem(
                    icon: Icons.assignment_turned_in_rounded,
                    tooltip: 'Cierre',
                  ),
                  CurvedNavItem(
                    icon: Icons.analytics_rounded,
                    tooltip: 'Reportes',
                  ),
                ],
              );
            },
          ),
        );
      }),
    );
  }
}
