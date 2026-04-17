import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppColors {
  static const background = Color(0xFF0D0B1E);
  static const surface = Color(0xFF1A1830);
  static const surfaceElevated = Color(0xFF201E3A);
  static const primary = Color(0xFF7C6FFF);
  static const primaryLight = Color(0xFF9D93FF);
  static const accent = Color(0xFF5B4FCC);
  static const cardBorder = Color(0xFF2E2B50);
  static const textPrimary = Color(0xFFFFFFFF);
  static const textSecondary = Color(0xFFABA8CC);
  static const textMuted = Color(0xFF6B6890);
  static const success = Color(0xFF4ADEAB);
  static const warning = Color(0xFFFFB347);
  static const error = Color(0xFFFF6B6B);

  static const gradientPrimary = LinearGradient(
    colors: [Color(0xFF7C6FFF), Color(0xFF5B4FCC)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const gradientBackground = LinearGradient(
    colors: [Color(0xFF0D0B1E), Color(0xFF13112A)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  static const gradientCard = LinearGradient(
    colors: [Color(0xFF201E3A), Color(0xFF1A1830)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const categoryHealth = Color(0xFF4ADEAB);
  static const categoryCareer = Color(0xFF7C6FFF);
  static const categoryMind = Color(0xFFFF8C69);
  static const categoryLearning = Color(0xFF64B5F6);
  static const categoryMindfulness = Color(0xFFBA68C8);
  static const categoryFinancial = Color(0xFFFFD54F);
}

class AppTheme {
  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: AppColors.background,
      colorScheme: const ColorScheme.dark(
        background: AppColors.background,
        surface: AppColors.surface,
        primary: AppColors.primary,
        secondary: AppColors.primaryLight,
        onBackground: AppColors.textPrimary,
        onSurface: AppColors.textPrimary,
        onPrimary: AppColors.textPrimary,
      ),
      textTheme: GoogleFonts.interTextTheme(
        const TextTheme(
          displayLarge: TextStyle(
            fontSize: 32,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
            letterSpacing: -0.5,
          ),
          displayMedium: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
            letterSpacing: -0.3,
          ),
          titleLarge: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
          titleMedium: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
          bodyLarge: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w400,
            color: AppColors.textPrimary,
          ),
          bodyMedium: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w400,
            color: AppColors.textSecondary,
          ),
          bodySmall: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w400,
            color: AppColors.textMuted,
          ),
          labelLarge: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
            letterSpacing: 0.5,
          ),
          labelSmall: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w600,
            color: AppColors.textMuted,
            letterSpacing: 1.2,
          ),
        ),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.background,
        elevation: 0,
        centerTitle: false,
        iconTheme: IconThemeData(color: AppColors.textPrimary),
        titleTextStyle: TextStyle(
          fontFamily: 'Inter',
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: AppColors.textPrimary,
        ),
      ),
      cardTheme: const CardThemeData(
        color: AppColors.surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(16)),
          side: BorderSide(color: AppColors.cardBorder, width: 1),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surfaceElevated,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.cardBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.cardBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
        ),
        labelStyle: const TextStyle(color: AppColors.textMuted),
        hintStyle: const TextStyle(color: AppColors.textMuted),
      ),
      dividerTheme: const DividerThemeData(
        color: AppColors.cardBorder,
        thickness: 1,
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return AppColors.primary;
          return AppColors.textMuted;
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return AppColors.primary.withOpacity(0.3);
          }
          return AppColors.surfaceElevated;
        }),
      ),
    );
  }

  static Color categoryColor(String category) {
    switch (category.toLowerCase()) {
      case 'sağlık':
      case 'health':
        return AppColors.categoryHealth;
      case 'kariyer':
      case 'career':
        return AppColors.categoryCareer;
      case 'zihinsel':
      case 'mind':
        return AppColors.categoryMind;
      case 'öğrenme':
      case 'learning':
        return AppColors.categoryLearning;
      case 'mindfulness':
        return AppColors.categoryMindfulness;
      case 'finansal':
      case 'financial':
        return AppColors.categoryFinancial;
      default:
        return AppColors.primary;
    }
  }

  static IconData categoryIcon(String category) {
    switch (category.toLowerCase()) {
      case 'sağlık':
      case 'health':
        return Icons.favorite_rounded;
      case 'kariyer':
      case 'career':
        return Icons.trending_up_rounded;
      case 'zihinsel':
      case 'mind':
        return Icons.psychology_rounded;
      case 'öğrenme':
      case 'learning':
        return Icons.auto_stories_rounded;
      case 'mindfulness':
        return Icons.self_improvement_rounded;
      case 'finansal':
      case 'financial':
        return Icons.account_balance_rounded;
      default:
        return Icons.star_rounded;
    }
  }
}
