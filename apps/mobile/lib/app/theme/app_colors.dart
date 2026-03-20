import 'package:flutter/material.dart';

/// Votio design token — color palette.
/// These are raw colors. Use [AppTheme] to apply them semantically.
abstract final class AppColors {
  // Brand
  static const primary = Color(0xFF6C63FF); // Electric violet
  static const primaryDark = Color(0xFF4A41DD);
  static const primaryLight = Color(0xFF9B95FF);

  static const secondary = Color(0xFFFF6B6B); // Coral
  static const accent = Color(0xFF43E6B5); // Mint

  // Neutrals
  static const grey50 = Color(0xFFFAFAFA);
  static const grey100 = Color(0xFFF5F5F5);
  static const grey200 = Color(0xFFEEEEEE);
  static const grey300 = Color(0xFFE0E0E0);
  static const grey400 = Color(0xFFBDBDBD);
  static const grey500 = Color(0xFF9E9E9E);
  static const grey600 = Color(0xFF757575);
  static const grey700 = Color(0xFF616161);
  static const grey800 = Color(0xFF424242);
  static const grey900 = Color(0xFF212121);

  // Semantic
  static const success = Color(0xFF4CAF50);
  static const warning = Color(0xFFFFC107);
  static const error = Color(0xFFEF5350);
  static const info = Color(0xFF42A5F5);

  // Surface — light
  static const surfaceLight = Color(0xFFFFFFFF);
  static const backgroundLight = Color(0xFFF8F8FF);
  static const cardLight = Color(0xFFFFFFFF);

  // Surface — dark
  static const surfaceDark = Color(0xFF1E1E2E);
  static const backgroundDark = Color(0xFF13131F);
  static const cardDark = Color(0xFF252535);
}
