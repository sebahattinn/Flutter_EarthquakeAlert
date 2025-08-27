import 'package:flutter/material.dart';

class AppColors {
  static const Color primary = Color(0xFFE63946);
  static const Color secondary = Color(0xFF457B9D);
  static const Color accent = Color(0xFFF77F00);
  static const Color background = Color(0xFFF1FAEE);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color textDark = Color(0xFF1D3557);
  static const Color textLight = Color(0xFF6C757D);

  // Magnitude colors
  static const Color magnitudeLow = Color(0xFF4CAF50);
  static const Color magnitudeMedium = Color(0xFFFFC107);
  static const Color magnitudeHigh = Color(0xFFFF9800);
  static const Color magnitudeVeryHigh = Color(0xFFF44336);

  static Color getMagnitudeColor(double magnitude) {
    if (magnitude < 3.0) return magnitudeLow;
    if (magnitude < 4.5) return magnitudeMedium;
    if (magnitude < 6.0) return magnitudeHigh;
    return magnitudeVeryHigh;
  }
}
