import 'package:flutter/material.dart';
import 'package:cafeteria_flutter/ui/theme/app_theme.dart';

class CurvedNavItem {
  final IconData icon;
  final String tooltip;

  const CurvedNavItem({
    required this.icon,
    required this.tooltip,
  });
}

/// Conserva el nombre anterior para no romper imports, pero reemplaza la barra
/// curva por una navegación limpia y profesional.
class CurvedBottomBar extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;
  final List<CurvedNavItem> items;

  const CurvedBottomBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
    required this.items,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Container(
        height: 76,
        decoration: const BoxDecoration(
          color: AppColors.surface,
          border: Border(top: BorderSide(color: AppColors.border)),
        ),
        child: Row(
          children: List.generate(items.length, (index) {
            final item = items[index];
            final selected = currentIndex == index;
            final isPrimaryAction = index == 2;

            return Expanded(
              child: InkWell(
                onTap: () => onTap(index),
                child: SizedBox.expand(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (isPrimaryAction)
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 180),
                          width: 46,
                          height: 42,
                          decoration: BoxDecoration(
                            color: selected
                                ? AppColors.graphite
                                : AppColors.amber,
                            borderRadius: BorderRadius.circular(14),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.graphite.withAlpha(18),
                                blurRadius: 12,
                                offset: const Offset(0, 5),
                              ),
                            ],
                          ),
                          child: Icon(
                            item.icon,
                            size: 22,
                            color: selected ? Colors.white : AppColors.graphite,
                          ),
                        )
                      else
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 180),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 13,
                            vertical: 5,
                          ),
                          decoration: BoxDecoration(
                            color: selected
                                ? AppColors.amberSoft
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            item.icon,
                            size: 22,
                            color: selected
                                ? AppColors.graphite
                                : AppColors.textSecondary,
                          ),
                        ),
                      const SizedBox(height: 4),
                      Text(
                        item.tooltip,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: selected
                              ? AppColors.textPrimary
                              : AppColors.textSecondary,
                          fontSize: 11,
                          height: 1,
                          fontWeight:
                              selected ? FontWeight.w800 : FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }),
        ),
      ),
    );
  }
}
