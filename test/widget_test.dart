import 'package:flutter_test/flutter_test.dart';
import 'package:cafeteria_flutter/main.dart';

void main() {
  testWidgets('App load smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const FlowStockApp());

    expect(find.byType(FlowStockApp), findsOneWidget);
    expect(find.text('FlowStock'), findsOneWidget);
  });
}
