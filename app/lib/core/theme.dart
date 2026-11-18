import 'package:flutter/material.dart';

/// Palet "Batik Merah Putih".
class C {
  static const cream = Color(0xFFFAF6EF);
  static const brown = Color(0xFF5C3A21);
  static const green = Color(0xFF5E7A3A);
  static const red = Color(0xFFD32F2F);
  static const gold = Color(0xFFD9A441);
  static const sage = Color(0xFF8DA16B);
  static const greenTint = Color(0xFFE9EEDF);
  static const goldTint = Color(0xFFF3E3BF);
  static const text = Color(0xFF2B1D14);
  static const muted = Color(0xFF6B5646);
  static const line = Color(0xFFE6DCCB);
}

ThemeData buildTheme() {
  final base = ColorScheme.fromSeed(seedColor: C.green, primary: C.green, secondary: C.gold, surface: C.cream, error: C.red);
  return ThemeData(
    useMaterial3: true,
    colorScheme: base,
    scaffoldBackgroundColor: C.cream,
    appBarTheme: const AppBarTheme(
      backgroundColor: C.cream, foregroundColor: C.text, elevation: 0, scrolledUnderElevation: 0, centerTitle: false,
      titleTextStyle: TextStyle(color: C.text, fontSize: 18, fontWeight: FontWeight.w700),
    ),
    textTheme: ThemeData.light().textTheme.apply(bodyColor: C.text, displayColor: C.text),
    inputDecorationTheme: InputDecorationTheme(
      filled: true, fillColor: Colors.white, contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: C.line)),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: C.line)),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: C.green, width: 1.6)),
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: Colors.white, indicatorColor: C.greenTint,
      labelTextStyle: WidgetStateProperty.all(const TextStyle(fontSize: 11, fontWeight: FontWeight.w600)),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: C.green, foregroundColor: Colors.white, minimumSize: const Size.fromHeight(50),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        textStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: C.brown, minimumSize: const Size.fromHeight(50), side: const BorderSide(color: C.line),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        textStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
      ),
    ),
  );
}
