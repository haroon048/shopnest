import 'package:flutter/material.dart';

// Midnight Luxe colors - poori app me yehi use honge.
class AppColors {
  AppColors._(); // is class ka object nahi banega

  static const Color background = Color(0xFF0B0B14); // app ka background
  static const Color surface = Color(0xFF15151F); // cards
  static const Color surface2 = Color(0xFF1D1D2B); // text fields, chat bubbles
  static const Color primaryViolet = Color(0xFF8B5CF6);
  static const Color primaryPink = Color(0xFFEC4899);
  static const Color accent = Color(0xFFFF6B6B); // badges, wishlist heart
  static const Color gold = Color(0xFFFFC531); // stars, premium tags
  static const Color textWhite = Color(0xFFFFFFFF);
  static const Color textMuted = Color(0xFFA3A3BC); // subtitles, hints
  static const Color success = Color(0xFF34D399); // in stock, online

  // Violet se pink tak gradient - buttons aur active states ke liye
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [primaryViolet, primaryPink],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}
