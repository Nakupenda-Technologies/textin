import 'package:flutter/material.dart';
import '../../shared/theme/app_theme.dart' as shared_theme;

class AppTheme {
  AppTheme._();

  static ThemeData get lightTheme => shared_theme.AppTheme.light;
  static ThemeData get darkTheme => shared_theme.AppTheme.dark;
}

