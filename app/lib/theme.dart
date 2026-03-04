import 'package:flutter/material.dart';

class AppTheme {
  static const Color primaryBlack = Color(0xFF000000);
  static const Color accentGrey = Color(0xFF757575);
  static const Color lightGrey = Color(0xFFEEEEEE);
  static const Color backgroundWhite = Color(0xFFFFFFFF);
  static const Color surfaceGrey = Color(0xFFF9F9F9);

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primaryBlack,
        primary: primaryBlack,
        secondary: accentGrey,
        surface: backgroundWhite,
        error: Colors.redAccent,
        onPrimary: Colors.white,
        onSecondary: Colors.white,
      ),
      scaffoldBackgroundColor: backgroundWhite,
      appBarTheme: const AppBarTheme(
        backgroundColor: backgroundWhite,
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,
        foregroundColor: primaryBlack,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.w900,
          color: primaryBlack,
          letterSpacing: -1.0,
        ),
        iconTheme: IconThemeData(color: primaryBlack),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: lightGrey, width: 1),
        ),
        color: backgroundWhite,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryBlack,
          foregroundColor: Colors.white,
          minimumSize: const Size(double.infinity, 52),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          textStyle: const TextStyle(
            fontWeight: FontWeight.w900, 
            fontSize: 14, 
            letterSpacing: 1.0,
          ),
          elevation: 0,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: primaryBlack,
          side: const BorderSide(color: primaryBlack, width: 1.5),
          minimumSize: const Size(double.infinity, 52),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          textStyle: const TextStyle(
            fontWeight: FontWeight.w900, 
            fontSize: 14,
            letterSpacing: 1.0,
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: lightGrey),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: lightGrey),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: primaryBlack, width: 2.0),
        ),
        labelStyle: const TextStyle(
          color: accentGrey, 
          fontSize: 10, 
          fontWeight: FontWeight.w900, 
          letterSpacing: 1.5,
        ),
      ),
      textTheme: const TextTheme(
        headlineLarge: TextStyle(fontWeight: FontWeight.w900, color: primaryBlack, letterSpacing: -2.0, fontSize: 32),
        headlineMedium: TextStyle(fontWeight: FontWeight.w900, color: primaryBlack, letterSpacing: -1.5, fontSize: 24),
        titleLarge: TextStyle(fontWeight: FontWeight.w900, color: primaryBlack, fontSize: 20, letterSpacing: -0.5),
        titleMedium: TextStyle(fontWeight: FontWeight.w700, color: primaryBlack, fontSize: 16),
        bodyLarge: TextStyle(color: primaryBlack, fontSize: 16, height: 1.5),
        bodyMedium: TextStyle(color: primaryBlack, fontSize: 14, height: 1.5),
        labelLarge: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1.5, fontSize: 10, color: accentGrey),
      ),
      iconTheme: const IconThemeData(color: primaryBlack),
      dividerTheme: const DividerThemeData(
        color: lightGrey,
        thickness: 1,
        space: 24,
      ),
      tabBarTheme: const TabBarThemeData(
        labelColor: primaryBlack,
        unselectedLabelColor: accentGrey,
        indicatorColor: primaryBlack,
        indicatorSize: TabBarIndicatorSize.label,
        labelStyle: TextStyle(fontWeight: FontWeight.w900, fontSize: 11, letterSpacing: 1.5),
        unselectedLabelStyle: TextStyle(fontWeight: FontWeight.w900, fontSize: 11, letterSpacing: 1.5),
      ),
      popupMenuTheme: const PopupMenuThemeData(
        color: backgroundWhite,
        surfaceTintColor: Colors.transparent,
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return primaryBlack;
          return accentGrey;
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return primaryBlack.withOpacity(0.12);
          return lightGrey;
        }),
        trackOutlineColor: WidgetStateProperty.all(Colors.transparent),
      ),
    );
  }
}

