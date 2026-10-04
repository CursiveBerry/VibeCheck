import 'package:flutter/material.dart';

/// Sticker-sheet palette: icy blue paper, navy ink outlines, loud candy fills.
class AppColors {
  static const paper = Color(0xFFE2F0FF);
  static const ink = Color(0xFF14213D);
  static const tangerine = Color(0xFFFF7B54);
  static const peach = Color(0xFFFFB38A);
  static const butter = Color(0xFFFFD84D);
  static const pink = Color(0xFFFFA3C4);
  static const sky = Color(0xFF7CC6F7);
  static const lime = Color(0xFFCFF45A);
  static const mint = Color(0xFF8FE8C8);
  static const danger = Color(0xFFD62839);
  static const disabled = Color(0xFFC9D3E0);
}

class VibeStyle {
  const VibeStyle(this.label, this.emoji, this.color);
  final String label;
  final String emoji;
  final Color color;
}

const vibeStyles = <VibeStyle>[
  VibeStyle('Stressed', '😵‍💫', AppColors.sky),
  VibeStyle('Chaotic', '🌀', AppColors.peach),
  VibeStyle('Wholesome', '🌸', AppColors.pink),
  VibeStyle('Caffeinated', '☕', AppColors.butter),
];

VibeStyle vibeStyleFor(String tag) => vibeStyles.firstWhere(
      (v) => v.label == tag,
      orElse: () => vibeStyles.first,
    );

class AppTheme {
  static ThemeData light() {
    final base = ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      scaffoldBackgroundColor: AppColors.paper,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.tangerine,
        brightness: Brightness.light,
      ),
    );

    return base.copyWith(
      textTheme: base.textTheme.apply(
        bodyColor: AppColors.ink,
        displayColor: AppColors.ink,
      ),
      textSelectionTheme: const TextSelectionThemeData(
        cursorColor: AppColors.ink,
        selectionHandleColor: AppColors.ink,
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: AppColors.ink,
        contentTextStyle: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w700,
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
    );
  }
}