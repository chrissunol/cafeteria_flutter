import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cafeteria_flutter/providers/inventory_provider.dart';
import 'package:cafeteria_flutter/ui/pages/splash_screen.dart';
import 'package:intl/date_symbol_data_local.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('es', null);
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => InventoryProvider()),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Paleta Graphite + Amber para una interfaz moderna de inventario
    const Color bgPrimary = Color(0xFFF5F6F8);
    const Color primaryBlack = Color(0xFF17181C);
    const Color accentAmber = Color(0xFFF4B740);
    const Color darkText = Color(0xFF181A1F);
    const Color softText = Color(0xFF717680);
    const Color errorRed = Color(0xFFDC4C4C);
    const Color softBorder = Color(0xFFE5E7EB);

    return MaterialApp(
      title: 'FlowStock',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.light,
        colorScheme: ColorScheme.fromSeed(
          seedColor: accentAmber,
          primary: primaryBlack,
          secondary: accentAmber,
          surface: Colors.white,
          onSurface: darkText,
          error: errorRed,
        ),
        scaffoldBackgroundColor: bgPrimary,

        // Tipografía
        textTheme: const TextTheme(
          headlineLarge: TextStyle(
              color: darkText, fontWeight: FontWeight.bold, fontSize: 28),
          headlineSmall: TextStyle(
              color: darkText, fontWeight: FontWeight.bold, fontSize: 20),
          titleLarge: TextStyle(
              color: darkText, fontWeight: FontWeight.bold, fontSize: 18),
          bodyLarge: TextStyle(color: darkText, fontSize: 16),
          bodyMedium: TextStyle(color: softText, fontSize: 14),
        ),

        cardTheme: CardThemeData(
          color: Colors.white,
          elevation: 2,
          shadowColor: primaryBlack.withAlpha(18),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: const BorderSide(color: softBorder, width: 1),
          ),
        ),

        appBarTheme: const AppBarTheme(
          centerTitle: true,
          elevation: 0,
          backgroundColor: Colors.white,
          surfaceTintColor: Colors.transparent,
          titleTextStyle: TextStyle(
            color: darkText,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
          iconTheme: IconThemeData(color: primaryBlack),
        ),

        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: accentAmber,
            foregroundColor: primaryBlack,
            elevation: 0,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
            textStyle: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ),

        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: softBorder),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: softBorder),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: accentAmber, width: 2),
          ),
          labelStyle: const TextStyle(color: softText),
          prefixIconColor: accentAmber,
        ),

        navigationBarTheme: NavigationBarThemeData(
          backgroundColor: Colors.white,
          indicatorColor: accentAmber.withAlpha(45),
          labelTextStyle: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) {
              return const TextStyle(
                  color: primaryBlack,
                  fontWeight: FontWeight.bold,
                  fontSize: 12);
            }
            return const TextStyle(color: softText, fontSize: 12);
          }),
          iconTheme: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) {
              return const IconThemeData(color: accentAmber);
            }
            return const IconThemeData(color: softText);
          }),
        ),

        floatingActionButtonTheme: FloatingActionButtonThemeData(
          backgroundColor: accentAmber,
          foregroundColor: primaryBlack,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
      ),
      home: const SplashScreen(),
    );
  }
}
