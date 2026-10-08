import 'package:flutter/material.dart';

const lime = Color(0xFFB5E60E);
const ink = Color(0xFF0A0A08);
const expenseColor = Color(0xFFE84A3A);
const incomeColor = Color(0xFF2DA966);
ThemeData trackerTheme(bool dark) {
  final background = dark ? const Color(0xFF0D0D0A) : const Color(0xFFF0EFE9);
  final surface = dark ? const Color(0xFF151411) : Colors.white;
  final foreground = dark ? const Color(0xFFF0EFE9) : ink;
  final border = dark ? const Color(0xFF322E23) : const Color(0xFFD8D5CB);
  final colors = ColorScheme.fromSeed(seedColor: lime,
      brightness: dark ? Brightness.dark : Brightness.light).copyWith(
    primary: dark ? const Color(0xFFC8F534) : lime,
    onPrimary: ink, surface: surface, onSurface: foreground,
    outline: border, error: dark ? const Color(0xFFFF6A5A) : expenseColor,
  );
  final theme = ThemeData(useMaterial3: true, colorScheme: colors,
    scaffoldBackgroundColor: background,
    appBarTheme: AppBarTheme(backgroundColor: background, foregroundColor: foreground,
      elevation: 0, centerTitle: false, titleTextStyle: TextStyle(color: foreground,
      fontSize: 22, fontWeight: FontWeight.w800, letterSpacing: -0.7)),
    cardTheme: CardThemeData(color: surface, elevation: 0, margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: border))),
    inputDecorationTheme: InputDecorationTheme(filled: true,
      fillColor: dark ? const Color(0xFF1C1B16) : const Color(0xFFF7F6F0),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: border)),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: border))),
    filledButtonTheme: FilledButtonThemeData(style: FilledButton.styleFrom(
      foregroundColor: ink, backgroundColor: lime, minimumSize: const Size(48, 52),
      textStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)))),
    floatingActionButtonTheme: const FloatingActionButtonThemeData(backgroundColor: lime, foregroundColor: ink),
    bottomSheetTheme: BottomSheetThemeData(backgroundColor: surface,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24)))),
    dividerTheme: DividerThemeData(color: border),
  );
  return theme.copyWith(textTheme: theme.textTheme.apply(bodyColor: foreground, displayColor: foreground));
}
