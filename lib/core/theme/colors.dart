import 'package:flutter/material.dart';
import '../../shared/theme/app_theme.dart';

class AppColors {
  AppColors._();

  static const Color primary = AppTheme.red;
  static const Color primaryDark = Color(0xFF8B0C1E);
  static const Color primaryLight = AppTheme.redbg;

  static const Color background = AppTheme.bg;
  static const Color surface = AppTheme.surface;
  static const Color textPrimary = AppTheme.text;
  static const Color textSecondary = AppTheme.textMuted;
  static const Color border = AppTheme.border;

  static const Color success = AppTheme.textingOnlineDot;
  static const Color error = AppTheme.red;
  static const Color warning = Color(0xFFF59E0B);
  static const Color info = Color(0xFF3B82F6);
}

