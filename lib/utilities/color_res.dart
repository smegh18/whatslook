import 'package:flutter/material.dart';

class ColorRes {
  /// Core neutrals
  static const Color blackPure = Color(0xFF000000); // Deep black (use for subtle shadows)
  static const Color whitePure = Color(0xFFFFFFFF); // Full white for readable text
  static const Color background = Color(0xFF202826)
; // dark greenish black
  
  static const Color appBarColro = Color(0xFF0F1412);
  /// Brand / accent
  static const Color themeGradient1 = Color(0x8825D366); // 53% opacity green gradient start
  static const Color themeGradient2 = Color(0x5525D366); // 33% opacity green gradient end
  static const Color themeAccentSolid = Color(0xFF25D366); // Solid green accent
  static const Color themeColor = Color(0x00000000); // Transparent canvas/background

  /// Text
  static const Color textDarkGrey = Color(0xCCFFFFFF); // 80% opacity white for primary text
  static const Color textLightGrey = Color(0x99FFFFFF); // 60% opacity for secondary text

  /// Utility / status colors
  static const Color orange = Color(0xFFFF8A3C); // Optional CTA accent
  static const Color green = Color(0xFF25D366); // Icon green
  static const Color green1 = Color(0xFF1EB859); // Slightly darker green for contrast
  static const Color likeRed = Color(0xFFFF5A5F); // Like / error accent
  static const Color textStoryBgGradient2 = Color(0x66FF5757); // Story overlay accent
  static const Color blueFollow = Color(0x6640C4FF); // Semi-transparent CTA blue
  static const Color battleProgressColor = Color(0x662CC3FF); // Semi-transparent progress
  static const Color buttonSecondary = Color(0xFF48524E); // Default secondary button surface
  static const Color buttonOverlay = Color(0xCC25302B); // Overlay button surface on media

  /// Glassmorphism / semi-transparent overlays
  static const Color bgLightGrey = Color(0x33FFFFFF); // 20% white
  static const Color bgGrey = Color(0x29FFFFFF); // 16% white
  static const Color bgMediumGrey = Color(0x4DFFFFFF); // 30% white
  static const Color disabledGrey = Color(0x61FFFFFF); // 38% white for disabled text
}
