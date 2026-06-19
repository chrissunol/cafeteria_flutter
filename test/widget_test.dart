import 'package:flutter_test/flutter_test.dart';
import 'package:cafeteria_flutter/main.dart';

void main() {
  testWidgets('App load smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const MyApp());

    // Basic check that the app starts. 
    // Since it starts with a SplashScreen, we just verify it doesn't crash immediately.
    expect(find.byType(MyApp), findsOneWidget);
  });
}
