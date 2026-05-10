import 'package:flutter/material.dart';

/// Thème Ma3ak — palette rose/violet douce (cute), accessible WCAG 4.5:1.
///
/// Light  : #E9C8CE #DEABAF #DC98BD #B384A7 #81657C
/// Dark   : #211A44 #5C5792 #9F8DC3 #BE9CC7 #E3BAD5
class AppTheme {
  AppTheme._();

  // ── Light palette ──────────────────────────────────────────────────────────
  static const Color _lPrimary         = Color(0xFFB384A7); // medium violet
  static const Color _lPrimaryDark     = Color(0xFF81657C); // deep violet
  static const Color _lPrimaryContainer= Color(0xFFE9C8CE); // blush rose
  static const Color _lSecondary       = Color(0xFFDC98BD); // pink-violet
  static const Color _lSecondaryContainer = Color(0xFFDEABAF); // soft pink
  static const Color _lSurface         = Color(0xFFFBF0F3); // near-white pinkish
  static const Color _lSurfaceVariant  = Color(0xFFF5E2E8); // card bg
  static const Color _lOnPrimary       = Colors.white;
  static const Color _lOnSurface       = Color(0xFF3B2133); // dark violet text
  static const Color _lOnSurfaceVariant= Color(0xFF7A5068); // muted text
  static const Color _lOutline         = Color(0xFFB384A7); // border
  static const Color _lError           = Color(0xFFB71C1C);

  // ── Dark palette ──────────────────────────────────────────────────────────
  static const Color _dScaffold        = Color(0xFF211A44); // deep night violet
  static const Color _dSurface         = Color(0xFF2E2660); // card surface
  static const Color _dSurfaceVariant  = Color(0xFF3B3475); // input bg
  static const Color _dPrimary         = Color(0xFF9F8DC3); // light violet
  static const Color _dPrimaryContainer= Color(0xFF5C5792); // medium violet
  static const Color _dSecondary       = Color(0xFFBE9CC7); // lavender
  static const Color _dOnPrimary       = Color(0xFF211A44);
  static const Color _dOnSurface       = Color(0xFFE3BAD5); // light pink text
  static const Color _dOnSurfaceVariant= Color(0xFFBE9CC7); // muted lavender
  static const Color _dOutline         = Color(0xFF9F8DC3);
  static const Color _dError           = Color(0xFFCF6679);

  // ── Shared radii ──────────────────────────────────────────────────────────
  static const double _radiusInput  = 18;
  static const double _radiusButton = 28;
  static const double _radiusCard   = 20;

  // ═══════════════════════════════════════════════════════════════════════════
  //  LIGHT THEME
  // ═══════════════════════════════════════════════════════════════════════════
  static ThemeData get light => ThemeData(
        useMaterial3: true,
        brightness: Brightness.light,
        fontFamily: 'Roboto',

        colorScheme: const ColorScheme.light(
          primary: _lPrimary,
          onPrimary: _lOnPrimary,
          primaryContainer: _lPrimaryContainer,
          onPrimaryContainer: _lPrimaryDark,
          secondary: _lSecondary,
          onSecondary: Colors.white,
          secondaryContainer: _lSecondaryContainer,
          onSecondaryContainer: _lPrimaryDark,
          surface: _lSurface,
          onSurface: _lOnSurface,
          surfaceContainerHighest: _lSurfaceVariant,
          onSurfaceVariant: _lOnSurfaceVariant,
          error: _lError,
          onError: Colors.white,
          outline: _lOutline,
          outlineVariant: Color(0xFFDEABAF),
        ),

        scaffoldBackgroundColor: _lSurface,

        // AppBar
        appBarTheme: const AppBarTheme(
          centerTitle: true,
          backgroundColor: _lPrimary,
          foregroundColor: _lOnPrimary,
          elevation: 0,
          scrolledUnderElevation: 2,
          shadowColor: Color(0x22B384A7),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(bottom: Radius.circular(20)),
          ),
        ),

        // Cards
        cardTheme: CardThemeData(
          elevation: 3,
          shadowColor: const Color(0x33B384A7),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(_radiusCard),
          ),
          color: _lSurfaceVariant,
          margin: const EdgeInsets.symmetric(horizontal: 0, vertical: 6),
        ),

        // ElevatedButton — pill shape
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: _lPrimary,
            foregroundColor: _lOnPrimary,
            minimumSize: const Size(88, 52),
            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
            elevation: 3,
            shadowColor: const Color(0x44B384A7),
            textStyle: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.3,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(_radiusButton),
            ),
          ),
        ),

        // OutlinedButton
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            foregroundColor: _lPrimary,
            minimumSize: const Size(88, 52),
            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
            side: const BorderSide(color: _lOutline, width: 1.5),
            textStyle: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(_radiusButton),
            ),
          ),
        ),

        // TextButton
        textButtonTheme: TextButtonThemeData(
          style: TextButton.styleFrom(
            foregroundColor: _lPrimary,
            textStyle: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),

        // FloatingActionButton
        floatingActionButtonTheme: const FloatingActionButtonThemeData(
          backgroundColor: _lSecondary,
          foregroundColor: Colors.white,
          elevation: 4,
          shape: CircleBorder(),
        ),

        // TextField / InputDecoration
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(_radiusInput),
            borderSide: const BorderSide(color: _lOutline, width: 1.2),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(_radiusInput),
            borderSide: const BorderSide(color: Color(0xFFDEABAF), width: 1.2),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(_radiusInput),
            borderSide: const BorderSide(color: _lPrimary, width: 2),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(_radiusInput),
            borderSide: const BorderSide(color: _lError, width: 1.5),
          ),
          focusedErrorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(_radiusInput),
            borderSide: const BorderSide(color: _lError, width: 2),
          ),
          labelStyle: TextStyle(fontSize: 14, color: _lOnSurfaceVariant),
          hintStyle: TextStyle(fontSize: 14, color: _lOnSurfaceVariant.withValues(alpha: 0.7)),
          prefixIconColor: _lPrimary,
          suffixIconColor: _lPrimary,
        ),

        // Chip
        chipTheme: ChipThemeData(
          backgroundColor: _lPrimaryContainer,
          selectedColor: _lPrimary,
          labelStyle: const TextStyle(fontSize: 13, color: _lOnSurface),
          side: const BorderSide(color: Color(0xFFDEABAF)),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        ),

        // BottomNavigationBar
        bottomNavigationBarTheme: const BottomNavigationBarThemeData(
          backgroundColor: Colors.white,
          selectedItemColor: _lPrimary,
          unselectedItemColor: _lOnSurfaceVariant,
          elevation: 12,
          type: BottomNavigationBarType.fixed,
          selectedLabelStyle: TextStyle(fontSize: 11, fontWeight: FontWeight.w700),
          unselectedLabelStyle: TextStyle(fontSize: 11),
        ),

        // NavigationBar (Material 3)
        navigationBarTheme: NavigationBarThemeData(
          backgroundColor: Colors.white,
          indicatorColor: _lPrimaryContainer,
          iconTheme: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) {
              return const IconThemeData(color: _lPrimary, size: 26);
            }
            return const IconThemeData(color: _lOnSurfaceVariant, size: 24);
          }),
          labelTextStyle: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) {
              return const TextStyle(
                  fontSize: 11, fontWeight: FontWeight.w700, color: _lPrimary);
            }
            return const TextStyle(fontSize: 11, color: _lOnSurfaceVariant);
          }),
          elevation: 8,
        ),

        // Divider
        dividerTheme: const DividerThemeData(
          color: Color(0xFFE9C8CE),
          thickness: 1,
          space: 1,
        ),

        // Snackbar
        snackBarTheme: SnackBarThemeData(
          backgroundColor: _lPrimaryDark,
          contentTextStyle: const TextStyle(color: Colors.white, fontSize: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          behavior: SnackBarBehavior.floating,
          elevation: 6,
        ),

        // Dialog
        dialogTheme: DialogThemeData(
          backgroundColor: _lSurface,
          elevation: 8,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(_radiusCard),
          ),
          titleTextStyle: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: _lOnSurface,
          ),
          contentTextStyle: TextStyle(fontSize: 14, color: _lOnSurfaceVariant),
        ),

        // Text
        textTheme: const TextTheme(
          displayMedium: TextStyle(
            fontSize: 36,
            fontWeight: FontWeight.w800,
            color: _lOnSurface,
            letterSpacing: -0.5,
          ),
          headlineMedium: TextStyle(
            fontSize: 26,
            fontWeight: FontWeight.bold,
            color: _lOnSurface,
            letterSpacing: -0.3,
          ),
          titleLarge: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: _lOnSurface,
          ),
          titleMedium: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: _lOnSurface,
          ),
          titleSmall: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: _lOnSurface,
          ),
          bodyLarge: TextStyle(fontSize: 16, color: _lOnSurface, height: 1.5),
          bodyMedium: TextStyle(fontSize: 14, color: _lOnSurface, height: 1.4),
          bodySmall: TextStyle(fontSize: 12, color: _lOnSurfaceVariant),
          labelLarge: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, letterSpacing: 0.2),
          labelMedium: TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
          labelSmall: TextStyle(fontSize: 10, fontWeight: FontWeight.w500, color: _lOnSurfaceVariant),
        ),
      );

  // ═══════════════════════════════════════════════════════════════════════════
  //  DARK THEME
  // ═══════════════════════════════════════════════════════════════════════════
  static ThemeData get dark => ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        fontFamily: 'Roboto',

        colorScheme: const ColorScheme.dark(
          primary: _dPrimary,
          onPrimary: _dOnPrimary,
          primaryContainer: _dPrimaryContainer,
          onPrimaryContainer: _dOnSurface,
          secondary: _dSecondary,
          onSecondary: _dOnPrimary,
          secondaryContainer: Color(0xFF4A3F6B),
          onSecondaryContainer: _dOnSurface,
          surface: _dSurface,
          onSurface: _dOnSurface,
          surfaceContainerHighest: _dSurfaceVariant,
          onSurfaceVariant: _dOnSurfaceVariant,
          error: _dError,
          onError: Color(0xFF211A44),
          outline: _dOutline,
          outlineVariant: Color(0xFF5C5792),
        ),

        scaffoldBackgroundColor: _dScaffold,

        // AppBar
        appBarTheme: const AppBarTheme(
          centerTitle: true,
          backgroundColor: _dSurface,
          foregroundColor: _dOnSurface,
          elevation: 0,
          scrolledUnderElevation: 2,
          shadowColor: Color(0x449F8DC3),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(bottom: Radius.circular(20)),
          ),
        ),

        // Cards
        cardTheme: CardThemeData(
          elevation: 4,
          shadowColor: const Color(0x669F8DC3),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(_radiusCard),
          ),
          color: _dSurface,
          margin: const EdgeInsets.symmetric(horizontal: 0, vertical: 6),
        ),

        // ElevatedButton
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: _dPrimary,
            foregroundColor: _dOnPrimary,
            minimumSize: const Size(88, 52),
            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
            elevation: 4,
            shadowColor: const Color(0x669F8DC3),
            textStyle: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.3,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(_radiusButton),
            ),
          ),
        ),

        // OutlinedButton
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            foregroundColor: _dPrimary,
            minimumSize: const Size(88, 52),
            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
            side: const BorderSide(color: _dOutline, width: 1.5),
            textStyle: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(_radiusButton),
            ),
          ),
        ),

        // TextButton
        textButtonTheme: TextButtonThemeData(
          style: TextButton.styleFrom(
            foregroundColor: _dPrimary,
            textStyle: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),

        // FloatingActionButton
        floatingActionButtonTheme: const FloatingActionButtonThemeData(
          backgroundColor: _dSecondary,
          foregroundColor: Color(0xFF211A44),
          elevation: 4,
          shape: CircleBorder(),
        ),

        // InputDecoration
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: _dSurfaceVariant,
          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(_radiusInput),
            borderSide: const BorderSide(color: _dOutline, width: 1.2),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(_radiusInput),
            borderSide: const BorderSide(color: Color(0xFF5C5792), width: 1.2),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(_radiusInput),
            borderSide: const BorderSide(color: _dPrimary, width: 2),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(_radiusInput),
            borderSide: const BorderSide(color: _dError, width: 1.5),
          ),
          focusedErrorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(_radiusInput),
            borderSide: const BorderSide(color: _dError, width: 2),
          ),
          labelStyle: const TextStyle(fontSize: 14, color: _dOnSurfaceVariant),
          hintStyle: TextStyle(fontSize: 14, color: _dOnSurfaceVariant.withValues(alpha: 0.7)),
          prefixIconColor: _dPrimary,
          suffixIconColor: _dPrimary,
        ),

        // Chip
        chipTheme: ChipThemeData(
          backgroundColor: _dPrimaryContainer,
          selectedColor: _dPrimary,
          labelStyle: const TextStyle(fontSize: 13, color: _dOnSurface),
          side: const BorderSide(color: Color(0xFF5C5792)),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        ),

        // BottomNavigationBar
        bottomNavigationBarTheme: const BottomNavigationBarThemeData(
          backgroundColor: _dSurface,
          selectedItemColor: _dPrimary,
          unselectedItemColor: _dOnSurfaceVariant,
          elevation: 12,
          type: BottomNavigationBarType.fixed,
          selectedLabelStyle: TextStyle(fontSize: 11, fontWeight: FontWeight.w700),
          unselectedLabelStyle: TextStyle(fontSize: 11),
        ),

        // NavigationBar (Material 3)
        navigationBarTheme: NavigationBarThemeData(
          backgroundColor: _dSurface,
          indicatorColor: _dPrimaryContainer,
          iconTheme: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) {
              return const IconThemeData(color: _dOnSurface, size: 26);
            }
            return const IconThemeData(color: _dOnSurfaceVariant, size: 24);
          }),
          labelTextStyle: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) {
              return const TextStyle(
                  fontSize: 11, fontWeight: FontWeight.w700, color: _dPrimary);
            }
            return const TextStyle(fontSize: 11, color: _dOnSurfaceVariant);
          }),
          elevation: 8,
        ),

        // Divider
        dividerTheme: const DividerThemeData(
          color: Color(0xFF5C5792),
          thickness: 1,
          space: 1,
        ),

        // Snackbar
        snackBarTheme: SnackBarThemeData(
          backgroundColor: _dSecondary,
          contentTextStyle: const TextStyle(color: Color(0xFF211A44), fontSize: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          behavior: SnackBarBehavior.floating,
          elevation: 6,
        ),

        // Dialog
        dialogTheme: DialogThemeData(
          backgroundColor: _dSurface,
          elevation: 8,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(_radiusCard),
          ),
          titleTextStyle: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: _dOnSurface,
          ),
          contentTextStyle: const TextStyle(fontSize: 14, color: _dOnSurfaceVariant),
        ),

        // Text
        textTheme: const TextTheme(
          displayMedium: TextStyle(
            fontSize: 36,
            fontWeight: FontWeight.w800,
            color: _dOnSurface,
            letterSpacing: -0.5,
          ),
          headlineMedium: TextStyle(
            fontSize: 26,
            fontWeight: FontWeight.bold,
            color: _dOnSurface,
            letterSpacing: -0.3,
          ),
          titleLarge: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: _dOnSurface,
          ),
          titleMedium: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: _dOnSurface,
          ),
          titleSmall: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: _dOnSurface,
          ),
          bodyLarge: TextStyle(fontSize: 16, color: _dOnSurface, height: 1.5),
          bodyMedium: TextStyle(fontSize: 14, color: _dOnSurface, height: 1.4),
          bodySmall: TextStyle(fontSize: 12, color: _dOnSurfaceVariant),
          labelLarge: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, letterSpacing: 0.2),
          labelMedium: TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
          labelSmall: TextStyle(fontSize: 10, fontWeight: FontWeight.w500, color: _dOnSurfaceVariant),
        ),
      );
}
