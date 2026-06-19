import 'package:flutter/material.dart';

class CurvedNavItem {
  final IconData icon;
  final String tooltip;

  const CurvedNavItem({
    required this.icon,
    required this.tooltip,
  });
}

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
    const double totalHeight = 92;

    // Barra negra
    const double barTop = 26;
    const double barHeight = 64;

    // Bordes redondeados de la barra
    const double borderRadius = 10;

    // Curva donde cae el ícono seleccionado
    const double notchWidth = 100;
    const double notchDepth = 36;

    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(18, 0, 18, 12),
        child: SizedBox(
          height: totalHeight,
          child: LayoutBuilder(
            builder: (context, constraints) {
              final double width = constraints.maxWidth;
              final double itemWidth = width / items.length;

              final double realSelectedCenterX =
                  itemWidth * currentIndex + itemWidth / 2;

              final double safeMargin = notchWidth / 2 + borderRadius + 4;

              final double selectedCenterX = realSelectedCenterX
                  .clamp(safeMargin, width - safeMargin)
                  .toDouble();

              return Stack(
                clipBehavior: Clip.none,
                children: [
                  Positioned.fill(
                    child: CustomPaint(
                      painter: _CurvedBarPainter(
                        selectedCenterX: selectedCenterX,
                        barTop: barTop,
                        barHeight: barHeight,
                        borderRadius: borderRadius,
                        notchWidth: notchWidth,
                        notchDepth: notchDepth,
                      ),
                    ),
                  ),

                  // Íconos normales
                  Positioned(
                    left: 0,
                    right: 0,
                    top: barTop,
                    height: barHeight,
                    child: Row(
                      children: List.generate(items.length, (index) {
                        final item = items[index];
                        final bool isSelected = index == currentIndex;

                        return Expanded(
                          child: GestureDetector(
                            onTap: () => onTap(index),
                            behavior: HitTestBehavior.opaque,
                            child: isSelected
                                ? const SizedBox.expand()
                                : Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        item.icon,
                                        color: Colors.white,
                                        size: 25,
                                      ),
                                      const SizedBox(height: 3),
                                      Text(
                                        item.tooltip,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 9.5,
                                          fontWeight: FontWeight.w600,
                                          height: 1,
                                        ),
                                      ),
                                    ],
                                  ),
                          ),
                        );
                      }),
                    ),
                  ),

                  // Círculo negro dentro de la curva con ícono blanco
                  AnimatedPositioned(
                    duration: const Duration(milliseconds: 180),
                    curve: Curves.easeOutCubic,
                    left: selectedCenterX - 22,
                    top: barTop - 12,
                    width: 44,
                    height: 44,
                    child: GestureDetector(
                      onTap: () => onTap(currentIndex),
                      behavior: HitTestBehavior.opaque,
                      child: Container(
                        width: 44,
                        height: 44,
                        decoration: const BoxDecoration(
                          color: Color(0xFF17181C),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          items[currentIndex].icon,
                          color: Colors.white,
                          size: 24,
                        ),
                      ),
                    ),
                  ),
                  // Texto del botón seleccionado
                  AnimatedPositioned(
                    duration: const Duration(milliseconds: 180),
                    curve: Curves.easeOutCubic,
                    left: selectedCenterX - 43,
                    top: barTop + 45,
                    width: 86,
                    child: Text(
                      items[currentIndex].tooltip,
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 9.5,
                        fontWeight: FontWeight.w700,
                        height: 1,
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

class _CurvedBarPainter extends CustomPainter {
  final double selectedCenterX;
  final double barTop;
  final double barHeight;
  final double borderRadius;
  final double notchWidth;
  final double notchDepth;

  _CurvedBarPainter({
    required this.selectedCenterX,
    required this.barTop,
    required this.barHeight,
    required this.borderRadius,
    required this.notchWidth,
    required this.notchDepth,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint()
      ..color = const Color(0xFF17181C)
      ..style = PaintingStyle.fill
      ..isAntiAlias = true;

    final double bottom = barTop + barHeight;

    final double notchStart = selectedCenterX - notchWidth / 2;
    final double notchEnd = selectedCenterX + notchWidth / 2;

    final Path path = Path();

    path.moveTo(borderRadius, barTop);

    path.lineTo(notchStart, barTop);

    // Curva izquierda hacia abajo
    path.cubicTo(
      selectedCenterX - 24,
      barTop,
      selectedCenterX - 24,
      barTop + notchDepth,
      selectedCenterX,
      barTop + notchDepth,
    );

    // Curva derecha hacia arriba
    path.cubicTo(
      selectedCenterX + 24,
      barTop + notchDepth,
      selectedCenterX + 24,
      barTop,
      notchEnd,
      barTop,
    );

    path.lineTo(size.width - borderRadius, barTop);

    path.quadraticBezierTo(
      size.width,
      barTop,
      size.width,
      barTop + borderRadius,
    );

    path.lineTo(size.width, bottom - borderRadius);

    path.quadraticBezierTo(
      size.width,
      bottom,
      size.width - borderRadius,
      bottom,
    );

    path.lineTo(borderRadius, bottom);

    path.quadraticBezierTo(
      0,
      bottom,
      0,
      bottom - borderRadius,
    );

    path.lineTo(0, barTop + borderRadius);

    path.quadraticBezierTo(
      0,
      barTop,
      borderRadius,
      barTop,
    );

    path.close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _CurvedBarPainter oldDelegate) {
    return oldDelegate.selectedCenterX != selectedCenterX ||
        oldDelegate.barTop != barTop ||
        oldDelegate.barHeight != barHeight ||
        oldDelegate.borderRadius != borderRadius ||
        oldDelegate.notchWidth != notchWidth ||
        oldDelegate.notchDepth != notchDepth;
  }
}
