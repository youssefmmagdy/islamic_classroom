import 'package:flutter/material.dart';

class AppTheme {
  static const Color primaryColor = Color(0xFF0F4620);
  static const Color secondaryColor = Color.fromARGB(255, 16, 71, 66);
  static const Color errorColor = Color(0xFFB00020);
  static const Color successColor = Color(0xFF0D4722);
  static const Color warningColor = Color(0xFFFF9800);
  static const Color backgroundColor = Color(0xFFFAFAFA); // Light mode - white
  static const Color darkBackgroundColor = Color(0xFF1E1E1E); // Dark mode - lightened black

  static ThemeData lightTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    scaffoldBackgroundColor: backgroundColor,
    colorScheme: ColorScheme.fromSeed(
      seedColor: primaryColor,
      brightness: Brightness.light,
      surface: backgroundColor,
    ).copyWith(
      surface: backgroundColor,
      surfaceContainerHighest: backgroundColor,
    ),
    appBarTheme: const AppBarTheme(
      centerTitle: true,
      elevation: 0,
    ),
    cardTheme: CardThemeData(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
    ),
  );

  static ThemeData darkTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    scaffoldBackgroundColor: darkBackgroundColor,
    colorScheme: ColorScheme.fromSeed(
      seedColor: const Color.fromARGB(255, 61, 133, 83),
      brightness: Brightness.dark,
      surface: darkBackgroundColor,
    ).copyWith(
      surface: darkBackgroundColor,
      surfaceContainerHighest: darkBackgroundColor,
    ),
    appBarTheme: const AppBarTheme(
      centerTitle: true,
      elevation: 0,
    ),
    cardTheme: CardThemeData(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
    ),
  );
}