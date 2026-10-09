import 'package:flutter/material.dart';

const lime = Color(0xFFB5E60E);
const ink = Color(0xFF0A0A08);
const expenseColor = Color(0xFFE84A3A);
const incomeColor = Color(0xFF2DA966);

/// Values from app/src/styles.css, including the web dark-mode hierarchy.
class WebPalette {
  WebPalette(this.dark);
  final bool dark;
  static WebPalette of(BuildContext context) =>
      WebPalette(Theme.of(context).brightness == Brightness.dark);
  Color get background =>
      dark ? const Color(0xFF0D0D0A) : const Color(0xFFF0EFE9);
  Color get surface => dark ? const Color(0xFF151411) : Colors.white;
  Color get elevated =>
      dark ? const Color(0xFF1C1B16) : const Color(0xFFF7F6F0);
  Color get sunken => dark ? const Color(0xFF080806) : const Color(0xFFE5E3D9);
  Color get border => dark ? const Color(0xFF242219) : const Color(0xFFD8D5CB);
  Color get foreground => dark ? const Color(0xFFF0EFE9) : ink;
  Color get secondary =>
      dark ? const Color(0xFFB4B0A2) : const Color(0xFF46433C);
  Color get muted => dark ? const Color(0xFF7C7870) : const Color(0xFF857F73);
  Color get onInk => dark ? ink : const Color(0xFFF0EFE9);
  Color get accent => dark ? const Color(0xFFC8F534) : lime;
  Color get limeSoft =>
      dark ? const Color(0xFF1B2D03) : const Color(0xFFEAF9C0);
  Color get limeInk => dark ? const Color(0xFFDEFF5C) : const Color(0xFF496203);
  Color get red => dark ? const Color(0xFFFF6A5A) : expenseColor;
  Color get redSoft => dark ? const Color(0xFF3A1510) : const Color(0xFFFEE0DB);
  Color get green => dark ? const Color(0xFF4CD089) : incomeColor;
  Color get greenSoft =>
      dark ? const Color(0xFF0F381E) : const Color(0xFFC8F1D8);
  Color get amber => dark ? const Color(0xFFFFC933) : const Color(0xFFF5B800);
  Color get amberSoft =>
      dark ? const Color(0xFF372D04) : const Color(0xFFFFF0BD);
  Color get emerald => dark ? const Color(0xFF34D399) : const Color(0xFF166534);
  Color get emeraldSoft =>
      dark ? const Color(0xFF052E16) : const Color(0xFFD1FAE5);
  Color get hero => dark ? elevated : ink;
}

TextStyle monoStyle({
  double size = 13,
  FontWeight weight = FontWeight.w700,
  Color? color,
}) => TextStyle(
  fontFamily: 'JetBrains Mono',
  fontSize: size,
  fontWeight: weight,
  color: color,
  fontFeatures: const [FontFeature.tabularFigures()],
  letterSpacing: -0.02 * size,
);

ThemeData trackerTheme(bool dark) {
  final p = WebPalette(dark);
  final colors =
      ColorScheme.fromSeed(
        seedColor: p.accent,
        brightness: dark ? Brightness.dark : Brightness.light,
      ).copyWith(
        primary: p.foreground,
        onPrimary: p.onInk,
        surface: p.surface,
        onSurface: p.foreground,
        onSurfaceVariant: p.muted,
        outline: p.border,
        error: p.red,
        surfaceTint: Colors.transparent,
      );
  final theme = ThemeData(
    useMaterial3: true,
    fontFamily: 'Plus Jakarta Sans',
    colorScheme: colors,
    scaffoldBackgroundColor: p.background,
    visualDensity: VisualDensity.standard,
    appBarTheme: AppBarTheme(
      backgroundColor: p.background,
      foregroundColor: p.foreground,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: false,
      titleSpacing: 20,
      titleTextStyle: TextStyle(
        fontFamily: 'Plus Jakarta Sans',
        color: p.foreground,
        fontSize: 22,
        fontWeight: FontWeight.w800,
        letterSpacing: -0.66,
      ),
    ),
    cardTheme: CardThemeData(
      color: p.surface,
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: BorderSide(color: p.border),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: p.elevated,
      hintStyle: TextStyle(fontSize: 14, color: p.muted),
      labelStyle: TextStyle(fontSize: 13, color: p.secondary),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: p.border),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: p.border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: p.foreground),
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        foregroundColor: p.onInk,
        backgroundColor: p.foreground,
        minimumSize: const Size(48, 52),
        textStyle: const TextStyle(
          fontFamily: 'Plus Jakarta Sans',
          fontWeight: FontWeight.w600,
          fontSize: 15,
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: p.secondary,
        side: BorderSide(color: p.border),
        textStyle: const TextStyle(
          fontFamily: 'Plus Jakarta Sans',
          fontSize: 13,
          fontWeight: FontWeight.w600,
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: p.secondary,
        textStyle: const TextStyle(
          fontFamily: 'Plus Jakarta Sans',
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    ),
    chipTheme: ChipThemeData(
      showCheckmark: false,
      selectedColor: p.foreground,
      backgroundColor: p.surface,
      side: BorderSide(color: p.border),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
      labelStyle: TextStyle(
        fontFamily: 'Plus Jakarta Sans',
        fontSize: 12,
        color: p.secondary,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
    ),
    floatingActionButtonTheme: FloatingActionButtonThemeData(
      backgroundColor: p.foreground,
      foregroundColor: p.accent,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
    ),
    bottomSheetTheme: BottomSheetThemeData(
      backgroundColor: p.surface,
      showDragHandle: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
    ),
    dividerTheme: DividerThemeData(color: p.border, thickness: 1, space: 1),
  );
  return theme.copyWith(
    textTheme: theme.textTheme.apply(
      bodyColor: p.foreground,
      displayColor: p.foreground,
    ),
  );
}
