import 'package:flutter/material.dart';

class AppColors {
  // Fondo claro amigable
  static const Color background = Color(0xFFF5F6FA); // Blanco con un sutil toque lavanda
  static const Color surface = Color(0xFFFFFFFF); // Blanco puro para tarjetas
  static const Color surfaceLight = Color(0xFFEBEEF5); // Lavanda grisáceo muy suave para bordes y campos inactivos

  // Acentos pastel
  static const Color primary = Color(0xFF98DDCA); // Menta pastel
  static const Color primaryDark = Color(0xFF25755E); // Verde menta oscuro para excelente contraste en textos y títulos
  static const Color secondary = Color(0xFFD5AAFF); // Lavanda/Lila pastel
  static const Color accent = Color(0xFFFFD3B6); // Durazno/Melocotón pastel

  // Pops de color pastel
  static const Color pink = Color(0xFFFFAAA5); // Rosa pastel
  static const Color purple = Color(0xFFE8AEFF); // Lila claro
  static const Color cyan = Color(0xFFA8DADC); // Celeste pastel
  static const Color lime = Color(0xFFE2F0CB); // Verde lima suave

  // Estados en tonos pastel legibles (para fondos)
  static const Color success = Color(0xFFC7F9CC); // Verde éxito suave
  static const Color error = Color(0xFFFFB5A7); // Coral suave para errores
  static const Color info = Color(0xFFA8DADC); // Celeste info

  // Textos e Iconos de estado (oscuros para legibilidad sobre fondos pastel)
  static const Color textSuccess = Color(0xFF1E5E43); // Verde oscuro para texto/iconos de éxito
  static const Color textError = Color(0xFFB03A2E); // Rojo coral oscuro para texto/iconos de error
  static const Color textInfo = Color(0xFF2E5B82); // Azul oscuro para texto/iconos informativos
  static const Color textWarning = Color(0xFF8C5B32); // Durazno oscuro/marrón suave para texto de alerta

  // Textos contrastantes y legibles sobre fondos claros
  static const Color textPrimary = Color(0xFF2C2F44); // Gris oscuro azulado suave
  static const Color textSecondary = Color(0xFF62667E); // Gris pizarra medio
  static const Color textMuted = Color(0xFF9499B0); // Gris claro para marcas de agua/inactivos
}

class AppTheme {
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      scaffoldBackgroundColor: AppColors.background,
      primaryColor: AppColors.primary,
      colorScheme: const ColorScheme.light(
        primary: AppColors.primary,
        secondary: AppColors.secondary,
        tertiary: AppColors.pink,
        surface: AppColors.surface,
        error: AppColors.error,
        onPrimary: AppColors.textPrimary, // texto oscuro sobre pastel se lee mejor que blanco
        onSecondary: AppColors.textPrimary,
        onSurface: AppColors.textPrimary,
        onTertiary: AppColors.textPrimary,
      ),
      cardTheme: CardThemeData(
        color: AppColors.surface,
        elevation: 2,
        shadowColor: AppColors.secondary.withValues(alpha: 0.15),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(
            color: AppColors.surfaceLight,
            width: 1,
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surfaceLight.withValues(alpha: 0.6),
        hintStyle: const TextStyle(color: AppColors.textMuted, fontSize: 14),
        labelStyle: const TextStyle(color: AppColors.textSecondary, fontSize: 14),
        floatingLabelStyle: const TextStyle(color: AppColors.primaryDark, fontWeight: FontWeight.w600),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: AppColors.surfaceLight),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: AppColors.surfaceLight),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppColors.primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppColors.error),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: AppColors.textPrimary,
          elevation: 0,
          minimumSize: const Size(double.infinity, 56),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.5,
          ),
        ),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: TextStyle(
          color: AppColors.textPrimary,
          fontSize: 20,
          fontWeight: FontWeight.bold,
          letterSpacing: 0.5,
        ),
        iconTheme: IconThemeData(color: AppColors.textPrimary),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: AppColors.primaryDark,
        foregroundColor: Colors.white,
        elevation: 3,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: AppColors.surfaceLight,
        labelStyle: const TextStyle(color: AppColors.textPrimary, fontSize: 13, fontWeight: FontWeight.w600),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return AppColors.primary;
          return AppColors.textMuted;
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return AppColors.primary.withValues(alpha: 0.4);
          }
          return AppColors.surfaceLight;
        }),
      ),
    );
  }

  // --- DECORATION HELPERS (versión pastel) ---
  static Decoration get glassDecoration {
    return BoxDecoration(
      color: AppColors.surface.withValues(alpha: 0.85),
      borderRadius: BorderRadius.circular(24),
      border: Border.all(
        color: AppColors.secondary.withValues(alpha: 0.15),
        width: 1.5,
      ),
    );
  }

  static Decoration get glassCardDecoration {
    return BoxDecoration(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(20),
      border: Border.all(
        color: AppColors.surfaceLight,
        width: 1,
      ),
      boxShadow: [
        BoxShadow(
          color: AppColors.secondary.withValues(alpha: 0.12),
          blurRadius: 16,
          offset: const Offset(0, 8),
        ),
      ],
    );
  }

  static Decoration get primaryGradientDecoration {
    return BoxDecoration(
      gradient: const LinearGradient(
        colors: [AppColors.primary, AppColors.secondary],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      borderRadius: BorderRadius.circular(16),
      boxShadow: [
        BoxShadow(
          color: AppColors.primary.withValues(alpha: 0.25),
          blurRadius: 12,
          offset: const Offset(0, 6),
        ),
      ],
    );
  }

  // Gradiente pastel rosa→lila→durazno, ideal para headers/banners
  static Decoration get vibrantGradientDecoration {
    return BoxDecoration(
      gradient: const LinearGradient(
        colors: [AppColors.purple, AppColors.pink, AppColors.accent],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      borderRadius: BorderRadius.circular(20),
      boxShadow: [
        BoxShadow(
          color: AppColors.pink.withValues(alpha: 0.25),
          blurRadius: 20,
          offset: const Offset(0, 10),
        ),
      ],
    );
  }

  // Gradiente pastel frío celeste→lavanda
  static Decoration get coolGradientDecoration {
    return BoxDecoration(
      gradient: const LinearGradient(
        colors: [AppColors.cyan, AppColors.secondary],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      borderRadius: BorderRadius.circular(16),
      boxShadow: [
        BoxShadow(
          color: AppColors.cyan.withValues(alpha: 0.25),
          blurRadius: 12,
          offset: const Offset(0, 6),
        ),
      ],
    );
  }

  // Lista de gradientes pastel para tarjetas/categorías con variedad de color
  static const List<List<Color>> categoryGradients = [
    [AppColors.primary, AppColors.cyan],
    [AppColors.secondary, AppColors.purple],
    [AppColors.pink, AppColors.accent],
    [AppColors.lime, AppColors.primary],
    [AppColors.accent, AppColors.error],
  ];
}